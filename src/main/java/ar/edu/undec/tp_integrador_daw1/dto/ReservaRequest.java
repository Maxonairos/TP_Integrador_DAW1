package ar.edu.undec.tp_integrador_daw1.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;

public record ReservaRequest(
        @NotNull(message = "es obligatorio") Long canchaId,
        @NotNull(message = "es obligatorio") Long clienteId,
        @NotNull(message = "es obligatorio")
        @Future(message = "debe ser una fecha y hora futura") LocalDateTime inicio,
        @NotNull(message = "es obligatorio")
        @Min(value = 1, message = "debe estar entre 1 y 3")
        @Max(value = 3, message = "debe estar entre 1 y 3") Integer horas) {
}
