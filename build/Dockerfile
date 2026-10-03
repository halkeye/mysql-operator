FROM quay.io/operator-framework/ansible-operator:v0.11.0

USER root
RUN pip3 install --no-cache-dir PyMySQL==1.0.2

RUN useradd -u ${USER_UID} ${USER_NAME}
USER ${USER_NAME}

COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
