package ar.edu.undec.tp_integrador_daw1.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import org.springframework.context.annotation.Configuration;

/** Documentación de la API. Se publica en /swagger-ui.html. */
@Configuration
@OpenAPIDefinition(
        info =
                @Info(
                        title = "Complejo Deportivo - API",
                        version = "1.0",
                        description =
                                "API REST para administrar canchas, clientes y reservas de un "
                                        + "complejo deportivo. Los errores se devuelven como "
                                        + "ProblemDetail (RFC 9457)."))
public class OpenApiConfig {
}
