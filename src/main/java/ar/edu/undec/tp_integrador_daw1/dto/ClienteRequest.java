package ar.edu.undec.tp_integrador_daw1.dto;

import jakarta.validation.constraints.NotBlank;

public record ClienteRequest(
        @NotBlank(message = "no debe estar vacío") String nombre,
        @NotBlank(message = "no debe estar vacío") String telefono) {
}
