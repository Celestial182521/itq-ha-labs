# ITQ – Alta Disponibilidad: Laboratorios Unidad 1

Alumno: celestial1825 · Entorno: Raspberry Pi 5 (Ubuntu 24.04, ARM64), Java 25, Quarkus 3.38

## Lab 1.1 – Medir baseline (sin resiliencia) → [`lab-1.1/`](lab-1.1/)

| Archivo | Contenido |
|---|---|
| `01-resumen-disponibilidad.png` | Resumen de las 200 solicitudes |
| `02-health-checks.png` | `/health`, `/ready`, `/live` validados a mano con curl |
| `03-respuestas-lentas.png` | Respuestas lentas (> 2.5 s) |
| `availability-baseline.txt` | Salida completa de `test-availability.sh` |
| `interpretacion.txt` | Interpretación de resultados |

Disponibilidad baseline: **0.68** (136 OK / 64 HTTP 500).

## Lab 1.2 – Patrones de resiliencia → [`lab-1.2/`](lab-1.2/)

`CatalogResource.java` con `@Timeout(800)`, `@Retry(maxRetries=2, delay=150)`,
`@CircuitBreaker(requestVolumeThreshold=10, failureRatio=0.7, delay=5000)` y `@Fallback(getCatalogFallback)`.

| Archivo | Contenido |
|---|---|
| `01-compilacion-mvnw.png` | `./mvnw compile` → BUILD SUCCESS |
| `02-prueba-degraded-cache.png` | Respuestas `DEGRADED_CACHE` / `SUCCESS` |
| `03-resumen-disponibilidad.png` | 200/200 HTTP 200, disponibilidad 1.0 |
| `04-analisis-1.1-vs-1.2.png` | Comparación Lab 1.1 vs Lab 1.2 |
| `diff-catalog.txt` | Diff de `CatalogResource.java` |
| `resilience-sample.txt` | Salida de `test-availability.sh` con patrones |
| `availability-baseline.txt` | Baseline de 1.1 usado para comparar |

| Métrica | Lab 1.1 | Lab 1.2 |
|---|---|---|
| Disponibilidad | 0.68 | **1.00** |
| Errores HTTP 500 | 64 | 0 |
| Latencia máx. | 3.03 s | 1.43 s |
| Latencia promedio | 0.574 s | 0.358 s |

## Código → [`catalog-service/`](catalog-service/)

Código fuente del servicio con los patrones de resiliencia aplicados
(ver `src/main/java/com/ecom/catalog/CatalogResource.java`).
