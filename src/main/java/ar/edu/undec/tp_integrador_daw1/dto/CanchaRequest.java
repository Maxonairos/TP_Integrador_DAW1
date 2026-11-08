package ar.edu.undec.tp_integrador_daw1.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

public record CanchaRequest(
        @NotBlank(message = "no debe estar vacío") String nombre,
        @NotBlank(message = "no debe estar vacío") String deporte,
        @NotNull(message = "es obligatorio")
        @Positive(message = "debe ser mayor que cero") BigDecimal precioHora) {
}
