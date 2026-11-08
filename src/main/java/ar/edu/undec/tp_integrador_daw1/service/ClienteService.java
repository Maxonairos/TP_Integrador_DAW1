package ar.edu.undec.tp_integrador_daw1.service;

import ar.edu.undec.tp_integrador_daw1.dto.ClienteRequest;
import ar.edu.undec.tp_integrador_daw1.dto.ClienteResponse;
import ar.edu.undec.tp_integrador_daw1.dto.ReservaResponse;
import ar.edu.undec.tp_integrador_daw1.entity.Cliente;
import ar.edu.undec.tp_integrador_daw1.exception.ConflictoException;
import ar.edu.undec.tp_integrador_daw1.exception.RecursoNoEncontradoException;
import ar.edu.undec.tp_integrador_daw1.repository.ClienteRepository;
import ar.edu.undec.tp_integrador_daw1.repository.ReservaRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class ClienteService {

    private final ClienteRepository clienteRepository;
    private final ReservaRepository reservaRepository;

    public ClienteService(
            ClienteRepository clienteRepository, ReservaRepository reservaRepository) {
        this.clienteRepository = clienteRepository;
        this.reservaRepository = reservaRepository;
    }

    public List<ClienteResponse> listar() {
        return clienteRepository.findAll().stream().map(ClienteResponse::desde).toList();
    }

    public ClienteResponse obtener(Long id) {
        return ClienteResponse.desde(buscarEntidad(id));
    }

    @Transactional
    public ClienteResponse crear(ClienteRequest request) {
        Cliente cliente = new Cliente();
        copiarDatos(cliente, request);
        return ClienteResponse.desde(clienteRepository.save(cliente));
    }

    @Transactional
    public ClienteResponse actualizar(Long id, ClienteRequest request) {
        Cliente cliente = buscarEntidad(id);
        copiarDatos(cliente, request);
        return ClienteResponse.desde(clienteRepository.save(cliente));
    }

    @Transactional
    public void eliminar(Long id) {
        Cliente cliente = buscarEntidad(id);
        if (reservaRepository.existsByClienteId(id)) {
            throw new ConflictoException(
                    "No se puede borrar el cliente porque tiene reservas asociadas");
        }
        clienteRepository.delete(cliente);
    }

    public List<ReservaResponse> reservas(Long clienteId) {
        buscarEntidad(clienteId);
        return reservaRepository.findByClienteIdOrderByInicioAsc(clienteId).stream()
                .map(ReservaResponse::desde)
                .toList();
    }

    private Cliente buscarEntidad(Long id) {
        return clienteRepository
                .findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe el cliente " + id));
    }

    private void copiarDatos(Cliente cliente, ClienteRequest request) {
        cliente.setNombre(request.nombre());
        cliente.setTelefono(request.telefono());
    }
}
