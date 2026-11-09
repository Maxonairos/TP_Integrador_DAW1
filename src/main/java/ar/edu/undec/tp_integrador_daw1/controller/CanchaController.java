package ar.edu.undec.tp_integrador_daw1.controller;

import ar.edu.undec.tp_integrador_daw1.dto.CanchaRequest;
import ar.edu.undec.tp_integrador_daw1.dto.CanchaResponse;
import ar.edu.undec.tp_integrador_daw1.dto.RecaudacionResponse;
import ar.edu.undec.tp_integrador_daw1.dto.ReservaResponse;
import ar.edu.undec.tp_integrador_daw1.service.CanchaService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.time.LocalDate;
import java.util.List;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/canchas")
@Tag(name = "Canchas", description = "ABM de canchas, disponibilidad horaria y recaudación")
public class CanchaController {

    private final CanchaService canchaService;

    public CanchaController(CanchaService canchaService) {
        this.canchaService = canchaService;
    }

    @GetMapping
    public List<CanchaResponse> listar() {
        return canchaService.listar();
    }

    @GetMapping("/{id}")
    public CanchaResponse obtener(@PathVariable Long id) {
        return canchaService.obtener(id);
    }

    @PostMapping
    public ResponseEntity<CanchaResponse> crear(@Valid @RequestBody CanchaRequest request) {
        CanchaResponse creada = canchaService.crear(request);
        URI location =
                ServletUriComponentsBuilder.fromCurrentRequest()
                        .path("/{id}")
                        .buildAndExpand(creada.id())
                        .toUri();
        return ResponseEntity.created(location).body(creada);
    }

    @PutMapping("/{id}")
    public CanchaResponse actualizar(
            @PathVariable Long id, @Valid @RequestBody CanchaRequest request) {
        return canchaService.actualizar(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@PathVariable Long id) {
        canchaService.eliminar(id);
    }

    @GetMapping("/{id}/reservas")
    public List<ReservaResponse> reservas(
            @PathVariable Long id,
            @RequestParam(required = false)
                    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
                    LocalDate fecha) {
        return canchaService.reservas(id, fecha);
    }

    /** Horas libres de la cancha entre las 08:00 y las 22:00 para la fecha indicada. */
    @GetMapping("/{id}/disponibilidad")
    public List<String> disponibilidad(
            @PathVariable Long id,
            @RequestParam(required = false)
                    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
                    LocalDate fecha) {
        return canchaService.disponibilidad(id, fecha);
    }

    /** Total facturado por cancha con reservas FINALIZADAS en el mes indicado (AAAA-MM). */
    @GetMapping("/recaudacion")
    public List<RecaudacionResponse> recaudacion(
            @RequestParam(required = false) String mes) {
        return canchaService.recaudacion(mes);
    }
}
