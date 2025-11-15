# Proyecto: Automatización de Infraestructura con Terraform y Ansible para PSS-TI
# Autor: Ignacio de Lecea Jiménez

## Índice


- [1. Requisitos Previos](#1-requisitos-previos)
  - [1.1. Entorno de desarrollo](#11-entorno-de-desarrollo)
  - [1.2. Herramientas IaC](#12-herramientas-iac)
  - [1.3. Proveedor Cloud](#13-proveedor-cloud)
  - [1.4. Red](#14-red)
  - [1.5. Paquetes adicionales](#15-paquetes-adicionales)
  - [1.6. Requisitos del ejercicio](#16-requisitos-del-ejercicio)


- [2. Pasos de Ejecución](#2-pasos-de-ejecución)
  - [2.1. Estructura del proyecto](#21-estructura-del-proyecto)
  - [2.2. Procedimiento de Terraform](#22-procedimiento-de-terraform)
  - [2.3. Procedimiento de Ansible](#23-procedimiento-de-ansible)


- [3. Integración entre Terraform y Ansible](#3-integración-entre-terraform-y-ansible)


---

## 1. Prerequisites

### 1.1. Entorno de desarrollo

- Máquina virtual Vagrant con CentOS Stream 9.

### 1.2. Herramientas IaC

- Terraform instalado.
- Ansible instalado.

### 1.3. Proveedor Cloud

- Cuenta AWS activa en región ap-south-1.
- Credenciales configuradas.

### 1.4. Red

- Conectividad a Internet en la VM.

### 1.5. Paquetes adicionales

- Python3 y pip.
- Paquetes Ansible para AWS.
- Herramientas auxiliares.

### 1.6. Requisitos del ejercicio

- Configurar S3 bucket para hosting de sitio web estático.

- Crear una VPC personalizada con:
  - 2 subredes públicas, 2 privadas, cada par en distintas AZ.
  - NAT Gateway en cada subred pública.

- Desplegar 2 EC2:
  - Webserver (Ubuntu + Apache o Nginx) en subred pública.
  - Database server (MariaDB o MySQL) en subred privada.

- Configurar grupos de seguridad para permitir:
  - HTTP (80), HTTPS (443) desde cualquier origen hacia webservers.
  - SSH (22) desde cualquier origen.
  - Acceso del webserver a la base de datos (e.g., puerto 3306).

- Configurar Ansible para:
  - Inventario dinámico usando plugin awsec2.
  - Roles para servidor web (instalación, configuración WordPress).
  - Roles para base de datos (instalación, configuración base datos).

- Crear script de despliegue que:
  - Ejecute `terraform apply` automáticamente.
  - Espere disponibilidad de instancias.
  - Ejecute playbook Ansible con inventario dinámico.

- Entregables:
  - Directorios `terraform` y `ansible`.
  - Script automatización (`Makefile`).
  - Archivo README.md con requisitos, pasos y descripción de integración.

## 2. Pasos de Ejecución

### 2.1. Estructura del proyecto
El proyecto se organiza en una estructura lógica y ordenada para facilitar la integración y despliegue conjunto:
```
.
├── Dev-Workspace
│   ├── ansible-dev
│   │   ├── ansible.cfg
│   │   ├── d-inventory
│   │   │   └── aws_ec2.yml
│   │   ├── roles
│   │   │   ├── database
│   │   │   └── webserver
│   │   └── site.yml
│   └── terraform-dev
│       ├── archivos.tf
│       ├── files
├── Makefile
└── README.m
```

### 2.2. Procedimiento de Terraform

1. **Generación de Bucket S3:**  
   Se crea un bucket con un sufijo aleatorio para garantizar unicidad y evitar conflictos. Se crea lo primero para evitar el problema huevo-gallina.
   El backend se configura para gestionar remotamente el archivo `.tfstate` asegurando la seguridad y persistencia del estado del proyecto.

2. **Política pública para bucket S3:**  
   Se crea una política que permite a cualquier usuario realizar la acción `s3:GetObject` en todos los objetos del bucket, para habilitar acceso público controlado.

3. **Deshabilitar bloqueo de acceso público:**  
   Se ajustan las configuraciones del bucket para permitir accesos públicos según la política definida.

4. **Configuración de sitio web estático S3:**  
   Se habilita el sitio web estático para el bucket, se suben los archivos `index.html` y `error.html`, y se genera un output para verificar la accesibilidad al endpoint.

5. **Creación de VPC personalizada:**  
   Se define una VPC con un rango CIDR específico.  
   Se crean dos subredes públicas y dos privadas, cada par en distintas zonas de disponibilidad para alta disponibilidad.

6. **Configuración de NAT Gateway y tablas de rutas:**  
   Se asigna un NAT Gateway por cada subred pública, utilizando IPs elásticas para asignación fija.  
   Las tablas de rutas públicas direccionan el tráfico a través del Internet Gateway, mientras que las tablas de rutas privadas dirigen el tráfico de salida hacia el NAT Gateway correspondiente.  
   Esta configuración permite que las instancias en subredes privadas accedan a Internet (para actualizaciones u otros servicios) sin exponerlas directamente.

7. **Definición de instancias EC2:**  
   Se selecciona la AMI `ubuntu-focal-20.04-amd64-server-*` por su estabilidad y amplia adopción en entornos web.  
   Se crea una instancia en la subred pública para el servidor web, que permite acceso directo mediante HTTP y HTTPS.  
   Se crea otra instancia en la subred privada para la base de datos, garantizando seguridad y aislamiento.  
   Dado que la instancia de base de datos no tiene IP pública, no es accesible directamente vía SSH.  
   Para conectarse a esta instancia, se utiliza el servidor web como host bastión, haciendo un salto SSH a través de este.  
   Sin embargo, la conexión directa desde Ansible a la base de datos usando este método no se ha logrado concretar completamente.

8. **Configuración de grupos de seguridad:**  
   - Grupo web: permite tráfico HTTP (80), HTTPS (443) y SSH (22) desde cualquier origen para asegurar accesibilidad y administración remota.  
   - Grupo base de datos: restringe el acceso al puerto MySQL (3306) solo desde el grupo web, garantizando seguridad y control de acceso estrictos.

### 2.3. Procedimiento de Ansible

1. **Inventario dinámico:**  
   Se utiliza el plugin `aws_ec2` para obtener el inventario de instancias en AWS en tiempo real, facilitando la gestión automática de nodos.

2. **Roles Ansible:**  
   - Rol `webserver` para instalar y configurar Apache y WordPress.  
   - Rol `database` para instalar y configurar MariaDB/MySQL.  
   Las tareas se distribuyen adecuadamente para asegurar la correcta configuración y despliegue de los servicios.

3. **Validación:**  
   Se ejecuta `ansible-inventory --graph` para verificar la correcta estructura y disponibilidad de los nodos en el inventario dinámico.

## 3. Integración entre Terraform y Ansible

La integración principal entre Terraform y Ansible se ha implementado mediante un archivo Makefile que automatiza y orquesta todo el flujo de trabajo de despliegue y configuración.
Este script realiza los siguientes pasos de forma automática:

1. Inicializa Terraform en el directorio correspondiente, preparando el entorno para la aplicación.
2. Ejecuta `terraform apply` con aprobación automática para crear toda la infraestructura definida.
3. Pausa la ejecución durante 80 segundos para asegurar que las instancias EC2 estén completamente provisionadas y accesibles.
4. Ejecuta el playbook de Ansible `site.yml` usando un inventario dinámico basado en AWS para configurar los servicios desplegados.
5. Ofrece un comando separado para destruir la infraestructura creada usando `terraform destroy`.

De esta manera, Terraform se encarga de la provisión y creación de recursos en la nube, mientras Ansible se ocupa de la configuración detallada de los servidores y aplicaciones una vez que la infraestructura está lista. El Makefile facilita la secuencia coordinada entre ambos, permitiendo que todo el proceso se realice con un solo comando, aumentando la eficiencia y minimizando errores humanos en la integración manual.

