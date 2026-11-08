package ar.edu.undec.tp_integrador_daw1.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;

public record ReservaRequest(

        @NotNull(message = "Seleccione una cancha para poder registrar la reserva.")
        Long canchaId,

        @NotNull(message = "Seleccione un cliente para poder registrar la reserva.")
        Long clienteId,

        @NotNull(message = "Ingrese la fecha y hora de inicio de la reserva.")
        @Future(message = "La fecha y hora de inicio debe ser posterior al momento actual.")
        LocalDateTime inicio,

        @NotNull(message = "Indique la duración de la reserva.")
        @Min(value = 1, message = "La reserva debe tener una duración mínima de 1 hora.")
        @Max(value = 3, message = "La reserva no puede superar las 3 horas de duración.")
        Integer horas

) {
}