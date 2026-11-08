package ar.edu.undec.tp_integrador_daw1.dto;

import java.math.BigDecimal;

public record RecaudacionResponse(
        Long canchaId, String canchaNombre, BigDecimal total) {
}
