---
name: actualizar-documentacion
description: Revisa cambios recientes del proyecto y actualiza toda la documentación en docs/ para que refleje el estado actual del código. Usar cuando se pida "actualizar documentación", "poner al día los docs", o tras un conjunto grande de cambios sin documentar.
---

Vas a revisar todo el proyecto y dejar `docs/` al día con el estado actual del código. Sigue estos pasos:

1. Lee `AGENTS.md` y `docs/estructura.md` para las convenciones de documentación (carpeta, formato de nombres).
2. Corre `git log --oneline -20` y `git diff` (o el rango que el usuario indique si lo proporciona) para ver qué cambió desde el último documento relevante.
3. Lista todos los archivos existentes en `docs/` y para cada uno decide: ¿sigue siendo preciso, quedó desactualizado, o ya no aplica (código eliminado)?
4. Para cada doc desactualizado, delega la actualización al subagente `documentador` — pásale contexto concreto: qué archivo de doc, qué cambió en el código, y por qué.
5. Si hay un sistema o cambio grande sin ningún doc, decide con el usuario si amerita uno nuevo antes de crearlo — no documentes por iniciativa propia si no está claro que se necesita.
6. No documentes código trivial o autoexplicativo. Prioriza sistemas, decisiones de arquitectura y comportamiento no obvio.
7. Al terminar, resume en una lista corta qué docs se actualizaron, cuáles se crearon, y cuáles se dejaron igual (y por qué).
