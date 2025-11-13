# CURSO PSS - ANSIBLE - CONFIGURACIÓN

## Índice
- [Configuración del entorno](#configuración-del-entorno)
- [Infraestructura como código](#infraestructura-como-código)
- [Configuración de Ansible](#configuración-de-ansible)
- [Principales módulos de Ansible](#principales-módulos-de-ansible)
- [Gestión de inventarios](#gestión-de-inventarios)
- [Comandos Ad Hoc y utilidades](#comandos-ad-hoc-y-utilidades)
- [Inventario estático](#inventario-estático)
- [Inventario dinámico](#inventario-dinámico)
- [Handlers](#handlers)
- [Roles](#roles)
- [Ansible-vault](#ansible-vault)
- [Comandos PowerShell](#comandos-powershell)

---

## Configuración del entorno
Para preparar el entorno de práctica con Ansible:
1. Clonar el repositorio base disponible en GitHub.
2. Configurar la máquina virtual utilizando VirtualBox.
3. Levantar las máquinas con el comando `vagrant up`.
4. Acceder mediante SSH a la máquina de control.
5. Instalar Ansible dentro del nodo de control.
6. Generar claves SSH y autorizar las máquinas gestionadas.
7. Verificar conectividad mediante conexión SSH sin contraseña.

---

## Infraestructura como código
Ansible permite definir toda la infraestructura —roles, inventarios y playbooks— en archivos bajo control de versiones.  
Esto garantiza reproducibilidad, consistencia e idempotencia en la configuración.

---

## Configuración de Ansible
Consideraciones básicas:
- Usar espacios en lugar de tabuladores para indentar.
- Añadir un primer task que recupere los facts del sistema (`gather_facts`).
- Configurar `ansible.cfg` para definir inventario y parámetros de ejecución (como ruta al inventario o privilege escalation).
- Ejecutar playbooks con `ansible-playbook` y validar sintaxis antes de aplicar cambios.
- Utilizar `register` para almacenar salidas de comandos.
- Organizar variables en directorios `group_vars` y `host_vars`.
- Emplear `ignore_errors` para gestionar errores esperados sin detener la ejecución.
- Controlar condiciones de fallo o cambio mediante `failed_when` y `changed_when`.
- Utilizar bloques `block`, `rescue` y `always` con lógica similar a try/catch.
- Consultar logs del sistema con `journalctl -xeu nombre_paquete.service`.
- Eliminar por completo servicios y sus rutas si es necesario cuando un paquete de problemas.
- En tareas de depuración, emplear el nivel de detalle `-vv` o el módulo `ansible.builtin.debug`.

---

## Principales módulos de Ansible

### yum
Gestiona la instalación, actualización o eliminación de paquetes en sistemas basados en RedHat.
- `present`: Asegura que el paquete esté instalado (si no, lo instala).
- `latest`: Instala o actualiza a la última versión disponible del paquete.
- `absent / removed`: Elimina el paquete si está instalado.
- `reinstalled`: Reinstala el paquete aunque esté instalado.

### service
Administra servicios permitiendo iniciar, detener, reiniciar o habilitar en el arranque.
- `started`: Inicia el servicio si no está corriendo.
- `stopped`: Detiene el servicio.
- `restarted`: Reinicia el servicio (detener y volver a iniciar).
- `reloaded`: Recarga la configuración del servicio sin detenerlo.
- `enabled`: Habilita el inicio automático del servicio al arrancar el sistema.

### copy
Permite transferir archivos desde el nodo de control hacia los hosts gestionados.

### template
Gestiona plantillas Jinja2 con soporte para variables dinámicas y control de permisos.

### user
Crea o modifica cuentas de usuario y grupos.

### file
Administra archivos y directorios, define permisos, enlaces o eliminación de recursos.
- file: para crear un archivo vacío (similar a touch).
- directory: para crear un directorio.
- absent: para eliminar el archivo o directorio.
- link: para crear un enlace simbólico.
- hard: para crear un enlace físico.
- touch: para actualizar tiempos de acceso/modificación sin cambiar contenido.

### debug
Muestra mensajes o variables durante la ejecución de un playbook.

### shell / command
Ejecuta comandos remotos en los hosts gestionados.

### lineinfile
Asegura la presencia o ausencia de una línea específica en un archivo de texto.

### fetch
Recupera archivos desde nodos remotos hacia el controlador de Ansible.

---

## Gestión de inventarios
El inventario define los hosts gestionados.  
Puede contener valores por host, grupo o globales.  
Se permite el uso de variables como `ansible_become=true` para escalar privilegios permanentemente.

---

## Comandos Ad Hoc y utilidades
Permiten ejecutar tareas puntuales sin crear playbooks.  
Usos frecuentes:
- Verificar disponibilidad de hosts.
- Reiniciar servicios.
- Crear usuarios o gestionar paquetes.
- Consultar documentación de módulos con `ansible-doc`.

---

## Inventario estático
Define manualmente los hosts y grupos en un archivo de texto plano.  
Se pueden agrupar máquinas bajo etiquetas o crear grupos de grupos mediante el sufijo `:children`.  
El grupo `all` aplica a todos los hosts y `ungrouped` a los no incluidos en otro grupo.

---

## Inventario dinámico
El inventario dinámico se genera mediante scripts o conectores a APIs, útil en entornos cloud donde las instancias cambian frecuentemente.  
Permite combinar inventarios estáticos y dinámicos en el mismo directorio.

Funciona por plugins, que vienen en collections. Vemos los que tenemos:
Ejecutando el comando: ansible-galaxy collection list

---

## Handlers
Los handlers son tareas que se ejecutan únicamente cuando son notificadas por otras tareas que han provocado un cambio.  
Se utilizan para acciones como reiniciar servicios tras modificar configuraciones y garantizan la idempotencia y eficiencia del playbook.

---

## Roles
Los roles permiten estructurar y reutilizar configuraciones.  
El parámetro `roles_path` se define en el archivo `ansible.cfg`.  
Pueden crearse con `ansible-galaxy role init`, que genera un esqueleto estándar compuesto por directorios como `tasks`, `handlers`, `templates`, `files` y `vars`.

---

## Ansible-vault
Herramienta que permite cifrar archivos y variables sensibles.  
Utiliza el algoritmo AES256 y contraseñas vault gestionadas mediante identificadores.  
Permite crear, editar, ver o reconfigurar contraseñas de archivos cifrados.  
Buena práctica: ubicar el archivo de contraseña en la raíz del proyecto.  
También admite cifrar variables individuales dentro de archivos YAML.