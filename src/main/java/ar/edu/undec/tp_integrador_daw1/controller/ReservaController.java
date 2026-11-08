package ar.edu.undec.tp_integrador_daw1.controller;

import ar.edu.undec.tp_integrador_daw1.dto.EstadoRequest;
import ar.edu.undec.tp_integrador_daw1.dto.ReservaFijaRequest;
import ar.edu.undec.tp_integrador_daw1.dto.ReservaRequest;
import ar.edu.undec.tp_integrador_daw1.dto.ReservaResponse;
import ar.edu.undec.tp_integrador_daw1.service.ReservaService;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/reservas")
public class ReservaController {

    private final ReservaService reservaService;

    public ReservaController(ReservaService reservaService) {
        this.reservaService = reservaService;
    }

    @GetMapping
    public List<ReservaResponse> listar() {
        return reservaService.listar();
    }

    @GetMapping("/{id}")
    public ReservaResponse obtener(@PathVariable Long id) {
        return reservaService.obtener(id);
    }

    @PostMapping
    public ResponseEntity<ReservaResponse> crear(@Valid @RequestBody ReservaRequest request) {
        ReservaResponse creada = reservaService.crear(request);
        URI location =
                ServletUriComponentsBuilder.fromCurrentRequest()
                        .path("/{id}")
                        .buildAndExpand(creada.id())
                        .toUri();
        return ResponseEntity.created(location).body(creada);
    }

    /** Crea la misma reserva N semanas seguidas; si alguna se superpone, no crea ninguna. */
    @PostMapping("/fijas")
    public ResponseEntity<List<ReservaResponse>> crearFijas(
            @Valid @RequestBody ReservaFijaRequest request) {
        List<ReservaResponse> creadas = reservaService.crearFijas(request);
        return ResponseEntity.created(URI.create("/api/reservas")).body(creadas);
    }

    @PutMapping("/{id}")
    public ReservaResponse actualizar(
            @PathVariable Long id, @Valid @RequestBody ReservaRequest request) {
        return reservaService.actualizar(id, request);
    }

    @PatchMapping("/{id}/estado")
    public ReservaResponse cambiarEstado(
            @PathVariable Long id, @Valid @RequestBody EstadoRequest request) {
        return reservaService.cambiarEstado(id, request.estado());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@PathVariable Long id) {
        reservaService.eliminar(id);
    }
}
