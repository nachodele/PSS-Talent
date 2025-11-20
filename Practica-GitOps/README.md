# Infraestructura y Automatización con Terraform y Ansible

- [0. Introducción: ¿Por qué del Proyecto?](#0-introducción-¿por-qué-del-proyecto)
- [1. Bucket S3](#1-bucket-s3)
- [2. Llaves SSH fuera del ciclo de Terraform](#2-llaves-ssh-fuera-del-ciclo-de-terraform)
- [3. Creación de la VPC y subredes](#3-creación-de-la-vpc-y-subredes)
- [4. Configuración de Grupos de Seguridad](#4-configuración-de-grupos-de-seguridad)
- [5. Configuración del Application Load Balancer (ALB)](#5-configuración-del-application-load-balancer-alb)
- [6. Configuración del Auto Scaling Group (ASG)](#6-configuración-del-auto-scaling-group-asg)
- [7. Creación de Base de Datos RDS PostgreSQL](#7-creación-de-base-de-datos-rds-postgresql)
- [8. Configuración de Ansible con inventario dinámico](#8-configuración-de-ansible-con-inventario-dinámico)
- [9. Integración con GitHub Actions para despliegue y destrucción](#9-integración-con-github-actions-para-despliegue-y-destrucción)

---

## 0. Introducción: ¿Por qué del Proyecto?  
Se necesitan servidores para alojar tiendas online, mostrar sus productos y procesar los pedidos. Sin servidores, la tienda no sería visible en Internet ni podría responder a los usuarios.

## 1. Bucket S3  
Un contenedor lógico en la nube, usado para almacenar objetos (archivos) de forma económica, segura y escalable.  
Se crea fuera del ciclo de Terraform para alojar el archivo de estado, evitando conflictos y manteniendo el estado persistente en equipo.

El backend remoto permite colaborar en equipo, mantener el estado persistente y evitar conflictos al aplicar cambios simultáneamente.
Se puede habilitar el bloqueo de estado mediante DynamoDB para evitar que varios usuarios modifiquen el estado al mismo tiempo.

## 2. Llaves SSH
Se generan un par de llaves SSH, pública para instancias y privada guardada como secreto seguro, para evitar exponer claves en el estado ni backend.

## 3. Creación de la VPC y subredes  
La VPC es el contenedor de red que aísla y protege los recursos.  
Las subredes públicas permiten acceso directo a Internet, mientras las privadas usan NAT Gateway para salida segura.  
Se definen en distintas zonas de disponibilidad (AZ) para proteger la continuidad ante fallos físicos.

## 4. Configuración de Grupos de Seguridad  
Actúan como firewalls para controlar el tráfico de entrada y salida de los recursos. Se crean grupos específicos:

- ALB permite HTTP (80)/HTTPS (443) desde cualquier origen.  
- ASG permite HTTP/HTTPS solo desde ALB y SSH (22) desde cualquier IP con clave.  
- RDS permite acceso solo desde ASG en puerto PostgreSQL (5432).

## 5. Configuración del Application Load Balancer (ALB)  
Distribuye el tráfico entre las instancias EC2 (target group definido), asegurando alta disponibilidad y escalabilidad.

## 6. Configuración del Auto Scaling Group (ASG)  
Gestiona el número de instancias EC2 ajustando automáticamente según la demanda, mejorando disponibilidad y optimizando costes.  
Se asocia a un launch template que define la configuración de las instancias.

Habria que configurar alarmas CloudWatch para uso de CPU alto y bajo, y las politicas de escalado para agregar o eliminar instancias.

## 7. Creación de Base de Datos RDS PostgreSQL  
Base de datos creada en subred privada, accesible solo por instancias EC2, para seguridad y facilidad en backups y restauraciones.
Está gestionada por AWS, lo que simplifica tareas como backups, restauración y escalado.

## 8. Configuración de Ansible con inventario dinámico  
Configruamos ansible con la clave privada para que pueda realizar en las instancias (hosts) las tareas especificadas en los roles, y definimos el inventario dinámico, ejecutandolo a través del playbook.

El plugin aws_ec2 de Ansible se usa para crear un inventario dinámico de las instancias en tiempo real, en el momento exacto que se ejecuta la automatización. Así se puede administrar automáticamente todas
las máquinas sin actualizar a mano el inventario.

## 9. Integración con GitHub Actions para despliegue y destrucción  
Integramos ambas herramientas en el github actions, donde definimos dos workflow on dispatch (ejecucion manual, en una situacion real se configuraria basandolo en eventos como push o pull request).
- Deploy: ejecuta terraform y ansible, desplegando la infraestructura configurada, tras una serie de chequeos sintácticos y estructurales.
- Destroy:  para destruir la infraestructura que ya no es útil.
