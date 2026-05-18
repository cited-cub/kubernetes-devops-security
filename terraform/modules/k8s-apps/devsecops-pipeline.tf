# Resources required by the devsecops-numeric-application Jenkins pipeline.
# All resources in this file are gated on var.enable_devsecops_pipeline.

# Create the kubernetes-devops-security Gitea repo that the Jenkinsfile pushes
# updated k8s manifests into after each build. ArgoCD watches this repo and
# rolls out changes — no kubectl is used by the pipeline.
resource "null_resource" "gitea_devsecops_repo" {
  count = var.enable_devsecops_pipeline ? 1 : 0

  triggers = {
    gitea_url = local.gitea_ext_url
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      GITEA_URL = local.gitea_ext_url
      OWNER     = var.gitea_admin_username
      PASS      = var.gitea_admin_password
    }
    command = <<-BASH
      set -euo pipefail
      API="$GITEA_URL/api/v1"
      echo "==> Creating Gitea repo: kubernetes-deveos-security"
      curl -sf -X POST "$API/user/repos" \
        -u "$OWNER:$PASS" \
        -H "Content-Type: application/json" \
        -d '{"name":"kubernetes-devops-security","auto_init":true,"private":false,"default_branch":"main"}' \
        -o /dev/null || echo "  (repo already exists, continuing)"
    BASH
  }

  depends_on = [helm_release.gitea]
}

# Inject the SonarQube token (generated dynamically by sonarqube_setup) into Jenkins
# as a secret-text credential via the Jenkins script console.
# The JCasC sonarqube-server config in jenkins-app.yaml.tftpl references this credential ID.
resource "null_resource" "jenkins_sonarqube_credential" {
  count = (var.enable_devsecops_pipeline && var.sonarqube_external_url != null) ? 1 : 0

  triggers = {
    sonarqube_url = var.sonarqube_external_url
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-BASH
      set -euo pipefail

      SONAR_TOKEN=$(cat /tmp/sonar_token.txt 2>/dev/null || true)
      if [[ -z "$SONAR_TOKEN" ]]; then
        echo "WARNING: /tmp/sonar_token.txt is empty or missing — SonarQube credential may already be present in Jenkins"
        exit 0
      fi

      echo "==> Waiting for Jenkins pod to be Running..."
      until kubectl get pod -n jenkins -l app.kubernetes.io/name=jenkins \
              -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q Running; do
        echo "  Jenkins pod not ready, retrying in 15s..."
        sleep 15
      done

      JENKINS_POD=$(kubectl get pod -n jenkins -l app.kubernetes.io/name=jenkins \
                    -o jsonpath='{.items[0].metadata.name}')
      JENKINS_PASS=$(kubectl -n jenkins get secret jenkins \
                     -o jsonpath='{.data.jenkins-admin-password}' | base64 -d)

      echo "==> Waiting for Jenkins API to be ready..."
      until kubectl exec -n jenkins "$JENKINS_POD" -c jenkins -- \
              curl -sf -u "admin:$JENKINS_PASS" http://localhost:8080/api/json -o /dev/null; do
        echo "  Jenkins API not ready, retrying in 15s..."
        sleep 15
      done

      sed "s|__SONAR_TOKEN__|$SONAR_TOKEN|g" > /tmp/sonar_credential.groovy <<'GROOVY'
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import hudson.util.Secret

def store  = SystemCredentialsProvider.getInstance().getStore()
def domain = Domain.global()
def existing = CredentialsMatchers.firstOrNull(
    store.getCredentials(domain), CredentialsMatchers.withId('sonarqube-token'))
if (existing) store.removeCredentials(domain, existing)
store.addCredentials(domain, new StringCredentialsImpl(
    CredentialsScope.GLOBAL, 'sonarqube-token',
    'SonarQube authentication token', Secret.fromString('__SONAR_TOKEN__')))
println 'SonarQube credential created'
GROOVY

      # Run crumb fetch and scriptText POST in a single kubectl exec so they
      # share one HTTP session (cookie jar) and the CSRF crumb stays valid.
      cat > /tmp/jenkins_cred_setup.sh <<'CRED_SCRIPT'
#!/bin/bash
set -euo pipefail
PASS="$1"
CRUMB_JSON=$(curl -s -c /tmp/jcookies.txt -u "admin:$PASS" \
  http://localhost:8080/crumbIssuer/api/json || true)
CRUMB_FIELD=$(printf '%s' "$CRUMB_JSON" | grep -o '"crumbRequestField":"[^"]*"' | cut -d'"' -f4 || true)
if [[ -z "$CRUMB_FIELD" ]]; then CRUMB_FIELD="Jenkins-Crumb"; fi
CRUMB_VALUE=$(printf '%s' "$CRUMB_JSON" | grep -o '"crumb":"[^"]*"' | cut -d'"' -f4 || true)
echo "==> Crumb: $CRUMB_FIELD=$CRUMB_VALUE"
curl -sf -X POST http://localhost:8080/scriptText \
  -u "admin:$PASS" \
  -b /tmp/jcookies.txt \
  -H "$CRUMB_FIELD: $CRUMB_VALUE" \
  --data-urlencode "script@/tmp/sonar_credential.groovy"
CRED_SCRIPT

      kubectl cp /tmp/sonar_credential.groovy \
        "jenkins/$JENKINS_POD:/tmp/sonar_credential.groovy" -c jenkins
      kubectl cp /tmp/jenkins_cred_setup.sh \
        "jenkins/$JENKINS_POD:/tmp/jenkins_cred_setup.sh" -c jenkins
      kubectl exec -n jenkins "$JENKINS_POD" -c jenkins -- \
        bash /tmp/jenkins_cred_setup.sh "$JENKINS_PASS"

      echo "==> SonarQube credential 'sonarqube-token' configured in Jenkins"
    BASH
  }

  depends_on = [null_resource.sonarqube_setup, null_resource.argocd_root_app]
}
