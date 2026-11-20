# Post-contenido — Unidad 12: Despliegue y CI/CD

## Descripción
Repositorio del laboratorio de la Unidad 12 de Programación Web —
Séptimo Semestre. Contiene la aplicación Spring Boot (CRUD de
Categoría y Producto) dockerizada con un Dockerfile multi-stage y
perfiles dev/prod (Parte 1), y su extensión con un pipeline de
integración continua con GitHub Actions y monitoreo con Spring Boot
Actuator (Parte 2).

![CI Status](https://github.com/<usuario>/apellido-post1-u12/actions/workflows/ci.yml/badge.svg)

## Parte 1 — Dockerización con Perfiles y Variables de Entorno
El Dockerfile multi-stage compila el proyecto con Maven en una
etapa JDK y ejecuta el JAR resultante en una etapa JRE Alpine con
un usuario no root. La configuración sensible se externaliza en
`application.properties` con placeholders `${VAR:default}`: sin
variables de entorno, la aplicación arranca con el perfil dev
(H2 en memoria); con `SPRING_PROFILES_ACTIVE=prod` y las variables
`DATASOURCE_URL` / `DATASOURCE_USER` / `DATASOURCE_PASSWORD` (y
`JWT_SECRET` si aplica), arranca con la configuración de producción.

### Variables de entorno
| Variable | Default | Descripción |
|---|---|---|
| `SPRING_PROFILES_ACTIVE` | `dev` | Perfil activo (`dev` / `prod`) |
| `PORT` | `8080` | Puerto del servidor |
| `DATASOURCE_URL` | H2 en memoria (dev) / PostgreSQL local (prod) | URL JDBC |
| `DATASOURCE_USER` | `sa` (dev) / `appuser` (prod) | Usuario de BD |
| `DATASOURCE_PASSWORD` | vacío | Contraseña de BD |
| `JWT_SECRET` | clave de desarrollo (dev) / vacío (prod) | Solo si el proyecto usa JWT |

> Nota: el perfil prod usa `ddl-auto=validate`. En una base de datos
> nueva y vacía (primer despliegue) defina temporalmente
> `SPRING_JPA_HIBERNATE_DDL_AUTO=update` para que se cree el esquema.

## Parte 2 — Pipeline CI/CD con GitHub Actions y Monitoreo con Actuator
El pipeline (`.github/workflows/ci.yml`) se activa automáticamente
en cada push y pull request a `main` y consta de dos jobs encadenados con `needs:`:
1. **build-and-test**: compila con Maven (caché de dependencias),
   ejecuta las pruebas con `mvn clean verify` y publica el reporte
   de Surefire como artefacto.
2. **docker-build**: construye la imagen con el mismo Dockerfile de
   la Parte 1, levanta el contenedor dentro del runner y hace un
   smoke test sobre `/actuator/health` (hasta 15 intentos), sin
   publicar la imagen en ningún registro externo. El contenedor de
   prueba se elimina siempre (`if: always()`).

## Despliegue (paso final manual)
La aplicación se despliega en Railway/Render a partir del mismo
Dockerfile, con las variables de entorno configuradas en el panel
de la plataforma:
- URL de la aplicación: https://mi-app.up.railway.app  *(reemplazar por la real)*
- /actuator/health: https://mi-app.up.railway.app/actuator/health

## Decisiones de diseño

### Parte 1
1. Placeholders con valor por defecto (`${VAR:default}`) en vez de
   placeholders estrictos: permite arrancar sin fricción en local
   y en CI, dejando los valores reales para producción. No se usa
   para credenciales de producción, que nunca deben tener un default utilizable.
2. `application-dev.properties` y `application-prod.properties` como
   archivos separados: hace explícito qué configuración corresponde
   a cada ambiente y reduce el riesgo de editar producción por error.
3. Imagen final eclipse-temurin JRE Alpine en vez de distroless:
   reduce el tamaño de la imagen sin sacrificar la posibilidad de
   depurar el contenedor con `docker exec`.

### Parte 2
1. Prueba mínima de contexto en vez de omitir la fase de pruebas:
   garantiza que el job de CI valide algo real.
2. El job docker-build construye y verifica la imagen con un smoke
   test contra /actuator/health, pero no la publica en ningún
   registro: evita exigir una cuenta externa y Secrets solo para
   aprobar el laboratorio.
3. Exposición de Actuator diferenciada por perfil (todos los
   endpoints en dev, solo health e info en prod): evita exponer
   públicamente información sensible como variables de entorno.

## Cómo compilar y ejecutar
1. Clonar el repositorio: `git clone https://github.com/<usuario>/apellido-post1-u12.git`
2. Construir la imagen localmente: `docker build -t mi-spring-app:local .`
3. Ejecutar con los valores por defecto (perfil dev):
   `docker run -p 8080:8080 mi-spring-app:local`
4. Ejecutar con perfil prod:
   ```bash
   docker run -p 8080:8080 \
     -e SPRING_PROFILES_ACTIVE=prod \
     -e DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/appdb \
     -e DATASOURCE_USER=appuser -e DATASOURCE_PASSWORD=apppass \
     -e JWT_SECRET=una-clave-larga-solo-para-produccion \
     mi-spring-app:local
   ```
5. Verificar el estado: `curl http://localhost:8080/actuator/health`
6. Probar la API: `curl http://localhost:8080/api/productos`
7. Consultar el pipeline en la pestaña Actions del repositorio

## Capturas de pantalla
![Imagen Docker construida localmente](capturas/docker-images.png)
![Contenedor respondiendo UP en local](capturas/actuator-health-local.png)
![GitHub Actions con checks verdes](capturas/github-actions.png)
![Smoke test respondiendo UP en el pipeline](capturas/smoke-test-log.png)
![Panel de Railway o Render con el despliegue activo](capturas/railway-panel.png)
![Endpoint /actuator/health respondiendo en la URL publica](capturas/railway-health.png)
