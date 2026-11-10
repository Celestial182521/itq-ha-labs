package com.ecom.catalog;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Random;
import java.util.logging.Logger;
import org.eclipse.microprofile.faulttolerance.CircuitBreaker;
import org.eclipse.microprofile.faulttolerance.Fallback;
import org.eclipse.microprofile.faulttolerance.Retry;
import org.eclipse.microprofile.faulttolerance.Timeout;

@Path("/v1/products")
public class CatalogResource {

    private static final Logger LOG = Logger.getLogger(CatalogResource.class.getName());
    private final Random random = new Random();

    private static final ThreadLocal<Integer> ATTEMPT_COUNT = ThreadLocal.withInitial(() -> 0);
    private static final ThreadLocal<Boolean> SHOULD_FAIL_FIRST_ATTEMPTS = ThreadLocal.withInitial(() -> false);

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Timeout(800)
    @Retry(maxRetries = 2, delay = 150)
    @CircuitBreaker(requestVolumeThreshold = 10, failureRatio = 0.7, delay = 5000)
    @Fallback(fallbackMethod = "getCatalogFallback")
    public Response getProducts() throws InterruptedException {
        try {
            ATTEMPT_COUNT.set(ATTEMPT_COUNT.get() + 1);
            int currentAttempt = ATTEMPT_COUNT.get();

            if (currentAttempt == 1) {
                LOG.info("════════════════════════════════════════════════════════════");
            }

            LOG.info("[Intento " + currentAttempt + "/3] Consultando catálogo de productos...");

            if (currentAttempt == 1) {
                // 60% de probabilidad de que los 3 intentos fallen
                SHOULD_FAIL_FIRST_ATTEMPTS.set(random.nextInt(10) < 6);
            }

            boolean shouldFail = SHOULD_FAIL_FIRST_ATTEMPTS.get();

            if (shouldFail && currentAttempt <= 3) {
                if (currentAttempt == 1) {
                    LOG.severe("[Intento " + currentAttempt + "/3] Falla de conexión a la base de datos primaria.");
                    throw new RuntimeException("Database connection timeout");
                } else if (currentAttempt == 2) {
                    LOG.warning("[Intento " + currentAttempt + "/3] Simulando latencia alta en consulta de catálogo...");
                    Thread.sleep(3000); // Lo corta @Timeout(800)
                } else if (currentAttempt == 3) {
                    LOG.severe("[Intento " + currentAttempt + "/3] Falla de conexión después de reintentos.");
                    throw new RuntimeException("Database connection timeout after retries");
                }
            }

            LOG.info("[Intento " + currentAttempt + "/3] Catálogo retornado exitosamente desde la base de datos primaria.");
            ATTEMPT_COUNT.set(0);
            SHOULD_FAIL_FIRST_ATTEMPTS.set(false);
            return Response.ok("{\"status\":\"SUCCESS\",\"data\":[\"Product A\",\"Product B\",\"Product C\"]}").build();

        } finally {
            // No resetear aquí: getCatalogFallback() lee el contador antes de resetearlo
        }
    }

    public Response getCatalogFallback() {
        int failedAttempts = ATTEMPT_COUNT.get();
        LOG.info("Fallback activado: Se agotaron todos los " + failedAttempts + " intentos. Sirviendo datos desde caché.");
        ATTEMPT_COUNT.set(0);
        SHOULD_FAIL_FIRST_ATTEMPTS.set(false);
        return Response.ok("{\"status\":\"DEGRADED_CACHE\",\"data\":[\"Cached Product A\",\"Cached Product B\"]}").build();
    }

    @GET
    @Path("/hello")
    @Produces(MediaType.TEXT_PLAIN)
    public String hello() {
        return "Catalog Service v1.0.0 - Unidad 1 - Alta Disponibilidad";
    }
}
