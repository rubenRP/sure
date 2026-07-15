# Configuración para Heroku - Solución de problemas de memoria y conexiones

## Problema

- Error R14: Memory quota exceeded (688MB de 512MB)
- Límite de conexiones de base de datos alcanzado (96.67%)

## Solución aplicada

### 1. Variables de entorno recomendadas

Para dynos Basic con un solo usuario, configuración mínima de memoria:

```bash
heroku config:set -a APP_NAME \
  RAILS_MAX_THREADS=1 \
  WEB_CONCURRENCY=1 \
  DB_POOL=1 \
  MALLOC_ARENA_MAX=2
```

`RAILS_MAX_THREADS` afecta también a Sidekiq vía `config/sidekiq.yml` (salvo que el
`Procfile` fije `-c N`, que tiene prioridad).

#### Buildpack jemalloc (recomendado)

Debe ir **antes** del buildpack de Ruby:

```bash
heroku buildpacks:add --index 1 https://github.com/gaffneyc/heroku-buildpack-jemalloc -a APP_NAME
```

Luego redeploy (`git push heroku main`).

### 2. Verificar límites de conexiones de tu base de datos

Revisa cuántas conexiones permite tu plan de base de datos:

```bash
heroku pg:info
```

Busca la línea "Connections" para ver el límite.

### 3. Cálculo de conexiones

```
Total conexiones ≈ (RAILS_MAX_THREADS × WEB_CONCURRENCY) + Sidekiq concurrency
                 = (1 × 1) + 1   # Procfile: sidekiq -c 1
                 = 2 conexiones
```

Si Sidekiq está en el mismo dyno que web, ajusta según necesites.

### 4. Opciones adicionales para reducir memoria

#### Opción A: Usar dyno Hobby (más memoria)

```bash
heroku dyno:type hobby
```

Esto te da 512MB garantizados + hasta 1GB burst.

#### Opción B: Si usas dyno gratuito/básico, considera:

- Reducir aún más threads: `RAILS_MAX_THREADS=1`
- Asegurarte de que solo tienes 1 dyno web corriendo
- Verificar que no tengas procesos Sidekiq duplicados

### 5. Monitorear el consumo

```bash
# Ver logs en tiempo real
heroku logs --tail

# Ver métricas
heroku ps

# Ver uso de base de datos
heroku pg:info
```

### 6. Despliegue

Después de configurar las variables de entorno:

```bash
git add .
git commit -m "Optimize Puma and database pool config for Heroku"
git push heroku main
```

## Verificación post-despliegue

1. Navega por varias páginas de la aplicación
2. Revisa los logs: `heroku logs --tail`
3. Verifica que no aparezcan errores R14
4. Comprueba el uso de conexiones en el email de monitoreo

## Notas adicionales

- Si sigues teniendo problemas, considera usar `heroku pg:psql` para verificar conexiones activas:

  ```sql
  SELECT count(*) FROM pg_stat_activity WHERE datname = current_database();
  ```

- Para ver qué proceso está usando más memoria, revisa los logs de Heroku buscando líneas con `sample#memory_total`.
