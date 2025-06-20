FROM rabbitmq:3-management

# Habilita os plugins necessários
RUN rabbitmq-plugins enable --offline rabbitmq_management
RUN rabbitmq-plugins enable --offline rabbitmq_shovel
RUN rabbitmq-plugins enable --offline rabbitmq_shovel_management