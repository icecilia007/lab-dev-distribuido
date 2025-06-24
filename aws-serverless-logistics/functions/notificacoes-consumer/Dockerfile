FROM public.ecr.aws/lambda/python:3.9

# Copiar requirements e instalar dependências
COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt

# Copiar código da função
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Handler da função
CMD ["lambda_function.handler"]