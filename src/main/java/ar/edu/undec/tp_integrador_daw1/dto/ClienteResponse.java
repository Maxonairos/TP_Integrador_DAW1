package ar.edu.undec.tp_integrador_daw1.dto;

import ar.edu.undec.tp_integrador_daw1.entity.Cliente;

public record ClienteResponse(Long id, String nombre, String telefono) {

    public static ClienteResponse desde(Cliente cliente) {
        return new ClienteResponse(cliente.getId(), cliente.getNombre(), cliente.getTelefono());
    }
}
