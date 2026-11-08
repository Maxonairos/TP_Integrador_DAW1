package ar.edu.undec.tp_integrador_daw1.dto;

import ar.edu.undec.tp_integrador_daw1.entity.Cancha;
import java.math.BigDecimal;

public record CanchaResponse(Long id, String nombre, String deporte, BigDecimal precioHora) {

    public static CanchaResponse desde(Cancha cancha) {
        return new CanchaResponse(
                cancha.getId(), cancha.getNombre(), cancha.getDeporte(), cancha.getPrecioHora());
    }
}
