package ar.edu.undec.tp_integrador_daw1.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record ClienteRequest(

        @NotBlank(message = "Ingrese el nombre y apellido del cliente.")
        String nombre,

        @NotBlank(message = "Ingrese un teléfono de contacto para el cliente.")
        @Pattern(
                regexp = "^\\+?[0-9\\s\\-()]{10,20}$",
                message = "Ingrese un número de teléfono válido. Ejemplo: 11 2345-6789."
        )
        String telefono

) {
}