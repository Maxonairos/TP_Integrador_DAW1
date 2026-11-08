package ar.edu.undec.tp_integrador_daw1.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

public record CanchaRequest(

        @NotBlank(message = "Ingrese el nombre de la cancha.")
        String nombre,

        @NotBlank(message = "Indique el deporte que se practica en la cancha.")
        String deporte,

        @NotNull(message = "Ingrese el precio por hora de la cancha.")
        @Positive(message = "El precio por hora debe ser mayor a cero.")
        BigDecimal precioHora

) {
}
