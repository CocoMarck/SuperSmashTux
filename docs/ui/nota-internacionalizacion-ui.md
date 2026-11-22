# Nota: Internacionalización de UI (`get_text(tag)`)

> **Decisión de rumbo (2026-11-21).** La UI de SuperSmashTux debe quedar **completa en inglés**.
> Hoy hay textos mezclados: `Start`, `Controls`, `Back to menu` y `Random`/`RANDOM` ya están en
> inglés, pero la mayoría de las pantallas sigue en español. La meta es que todo texto visible pase
> por un helper `get_text(tag)` que devuelva el texto según el idioma configurado o el del sistema.
>
> Estado: **FALTA**. Este documento registra la decisión y el plan, no una implementación existente.

## Principios

1. **Inglés como base**: la columna `en` del CSV es la fuente y el fallback del proyecto.
2. **Tags, no frases sueltas**: las claves canónicas son `lower-kebab-case`, estables y ASCII
   (`character-menu-title`, `hud-fight`). `get_text()` normaliza antes de buscar, así que también
   acepta texto del tipo `"Hello pipol_ Gg"` y resuelve `hello-pipol-gg`.
3. **Nombres propios no se traducen**: `Tux` y `Bob` quedan igual. La entrada de selección
   aleatoria sí es texto de UI y pasa por tag (`character-random`).
4. **Glifo estable**: `CharacterCatalog.Entry.glyph` no debe derivarse de `display_name`, porque el
   texto cambiará con el idioma. Para `standard`/`tux` se fija una letra y para la selección
   aleatoria `?`.
5. **Sin `var name` en `Person`**: choca con `Node.name` de Godot. El nombre visible vive en el
   catálogo/registry; `Person` solo guarda `id`.

## Formato de datos

Archivo: `data/locale/strings.csv`, UTF-8 **sin BOM**:

```csv
keys,en,es,_comment
character-random,Random,Aleatorio,Etiqueta del roster
character-menu-title,Character Selection,Selección de personaje,
hud-fight,FIGHT!,¡PELEA!,Anuncio al terminar la cuenta
hud-winner,Winner,Ganador,
hud-draw,Draw,Empate,
key-back,Back,Regresar,
```

- La primera columna son tags únicos en `lower-kebab-case`; las demás columnas son locales (`en`, `es`).
- Las columnas que empiezan con `_` se ignoran al importar (son comentarios).
- Para comas, comillas o saltos de línea, entrecomillar el valor y duplicar las comillas internas.
- Godot importa el CSV como traducción. Hay que registrarlo en
  **Project Settings → Localization → Translations** y dejar `en` como
  **Internationalization → Locale** de fallback. Referencia:
  [Localization using spreadsheets](https://docs.godotengine.org/en/4.7/tutorials/i18n/localization_using_spreadsheets.html).

## Helper `get_text(tag)`

Envoltorio delgado sobre `tr()` (o `TranslationServer.translate()`), con normalización de tags,
fallback al texto original y log si falta la traducción, y placeholders:

```gdscript
class_name I18n
extends RefCounted

const ACCENTED: String = "áàäâãåéèëêíìïîóòöôõúùüûñçýÿ"
const PLAIN: String = "aaaaaaeeeeiiiiooooouuuuncyy"

static func normalize_tag(tag: String) -> String:
	var s: String = tag.strip_edges().to_lower()
	for i in ACCENTED.length():
		s = s.replace(ACCENTED[i], PLAIN[i])
	var invalid: RegEx = RegEx.create_from_string("[^a-z0-9]+")
	return invalid.sub(s, "-", true).lstrip("-").rstrip("-")

static func get_text(tag: String, values: Dictionary = {}) -> String:
	var key: String = normalize_tag(tag)
	var text: String = String(tr(key))
	if text.is_empty() or text == key:
		push_warning("[I18n] Missing translation for '%s' (original: '%s')" % [key, tag])
		text = tag
	return text.format(values) if not values.is_empty() else text
```

Uso:

```gdscript
_name_label.text = I18n.get_text("character-random")
_status.text = I18n.get_text("hud-lives", { "count": lives })
```

- Normalización automática: `Hello pipol_ Gg` → `hello-pipol-gg`; `¡Pelea!` → `pelea`;
  `Árbol` → `arbol`.
- Si no existe la traducción, devolver el texto original (`tag`) y avisar con
  `push_warning("[I18n] Missing translation for '%s' (original: '%s')")`. Nunca devolver el slug.
- Para plurales usar `tr_n()` en vez de `tr()`.
- Para texto estático de `.tscn`, el tag en `Label.text` / `Button.text` puede usar la
  auto-traducción de Godot; para texto dinámico, siempre `I18n.get_text()`.
- Los tags se pueden poner como `StringName` en el código y convertir a `String` dentro del helper;
  la API pública queda `get_text(tag)`.

## Idioma configurado

Archivo: `user://settings.cfg` (nuevo, separado de `user://controls.cfg`):

```ini
[language]
locale = "auto"
```

Valores:

| Valor | Significado |
|---|---|
| `auto` | Usa `OS.get_locale_language()`. Si no hay traducción, cae al fallback `en`. |
| `en` | Fuerza inglés. |
| `es` | Fuerza español. |

Resolución al arrancar:

```gdscript
var locale: String = _read_locale_from_settings() # "auto" por defecto
if locale == "auto":
	locale = OS.get_locale_language()
TranslationServer.set_locale(locale)
```

Referencias:
[Internationalizing games](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html)
y [TranslationServer](https://docs.godotengine.org/en/4.7/classes/class_translationserver.html).

## Inventario inicial de textos

Textos ya en inglés: `Start`, `Controls`, `Back to menu`, `Player1`/`Player2`, `None`, y la
etiqueta del roster `RANDOM`/`Random` (hoy hay discrepancia entre `character_catalog.gd` y
`roster_tile.tscn`/`slot_card.tscn`; debe unificarse con `character-random`).

Pendientes obvios:

| Dominio | Ejemplos |
|---|---|
| `character_menu.tscn` / `character_menu.gd` | `Selección de personaje`, `Personajes`, `Jugadores`, `Mover`, `Seleccionar`, `Cancelar`, `Confirmar` |
| `match_menu.tscn` / `match_menu.gd` | `Configuración de partida`, `Escenarios`, `Vista previa`, `Reglas`, `Mapa 1`, `Mover`, `Seleccionar`, `Cancelar`, `Pelear` |
| `slot_card.tscn` / `slot_card.gd` | `libre`, `Clic izq.`, `para unirte`, `> eligiendo`, `> asignar CPU`, `JUGADOR`, `CPU`, `agregar CPU` |
| `fight_hud.tscn` / `fight_hud.gd` | `Pausar`, `> ¡PELEA!` |
| `announcement.tscn` / `.gd` | `> ¡PELEA!` (repetido) |
| `end_window.tscn` / `.gd` | `Ganador`, `Empate`, `> ¡SE ACABÓ!`, `> SIN GANADOR`, `Pulsa`, `Enter`, `para continuar` |
| `key_hint.tscn` / `.gd` | `Esc`, `Regresar` |
| `ready_banner.tscn` / `character_menu.tscn` | `¿LISTOS?`, `¿CONTINUAR?`, `Sí`, `No` |
| `ui/components/match_menu/rule_row.tscn` / `ui/match_menu.tscn` | `Vidas`, `Tiempo`, `por jugador · 1 a 10`, `minutos · ∞ sin límite` |

Los números (`3`, `00:00`, `∞`, `%`) y las teclas (`K`, `Tab`, `Enter`, `WASD`) no necesitan tag;
sí lo necesitan las palabras que los acompañan (`min`, `Pulsa`, `para continuar`).

## Fases de migración

1. **Base (FALTA)**: crear `I18n`, `strings.csv`, registrar la traducción y leer `user://settings.cfg`.
2. **Selección (FALTA)**: unificar `character-random`, tags del `character_menu`, `roster_tile` y
   `slot_card`; fijar glyphs estables.
3. **HUD (FALTA)**: `fight_hud`, `announcement`, `end_window`, `player_plate`, `key_hint`.
4. **Resto (FALTA)**: `main_menu`, `controls_menu` y cualquier literal que quede en `.tscn`.

Al terminar cada fase: buscar literales en español con `grep` sobre `scripts/ui/` y `ui/`, y
verificar que el juego arranque con `locale = "auto"`, `en` y `es`.

## Ver también

- [nota-ui-responsiva.md](nota-ui-responsiva.md): anclas/containers, no escalado global.
- [../changelog.md](../changelog.md): entrada `Internacionalización de UI`.
- [../arquitectura/nota-power-fighter-configurer.md](../arquitectura/nota-power-fighter-configurer.md):
  de dónde sale `display_name`.
