FROM quay.io/operator-framework/ansible-operator:v1.42.3

USER root
RUN python3 -m ensurepip \
    && python3 -m pip install --no-cache-dir PyMySQL==1.2.3
USER 1001

RUN ansible-galaxy collection install ansible.mysql:==5.2.0 \
      --collections-path ${HOME}/.ansible/collections

COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
