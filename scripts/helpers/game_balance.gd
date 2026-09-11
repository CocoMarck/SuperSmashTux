class_name GameBalance
'''
Archivo de constantes y enumeraciones globales del balance del juego

- Tiempo de stun que igual para todos.
- Pesos de personajes estandar. Ligero, Medio, Pesado.
- Alturas: Pequeño, Normal, Grande.
- Duración de habilidades compartidas de forma igualitaria: Como duración de shield. (Grab puede variar).
'''
# GravityBody3D | Plataformas de un solo sentido.
const DROP_THROUGH_TIME :float = 0.25    # segundos que se ignora la plataforma tras el tap de abajo
const ONE_WAY_MARGIN :float = 0.1        # franja por debajo de la cara superior de la plataforma, pa no quedarse atorado
const ONE_WAY_COYOTE_TIME :float = 0.3   # tiempo de perdon al salirse de la orilla y querer regresar

# Person | Input
const INPUT_BUFFER_WINDOW: float = 0.15
const TIMES_PRESSING_DOWN: int = 2

# Person | Agarre de orillas.
const LEDGE_HANG_OFFSET := 0.3     # que tan separado de la orilla se queda colgado
const LEDGE_RELEASE_TIME := 0.3    # cooldown tras soltarse, pa no re-agarrarse solo

# Person | Damage move
# Duración de base y máxima knockback, del no poder hacer nada, y del movimiento por el knockback.
const BASE_HITSTUN_DURATION :float = 0.3 # 0.3 (aceptable).
const MAX_HITSTUN_DURATION :float = 0.7 # 0.5 (aceptable) 1.0 (largo).
const KNOCKBACK_DECAY_TIME :float = 0.3 # 0.3 (aceptable) 0.5 (largo)

# Person | Stun move
const STUN_DURATION_ON_FLOOR: float = 1.0
const STUN_DAMAGE_THRESHOLD: float = 0.15 # Porcentaje minimo para habilitar stun
const STUN_GETUP_NEUTRAL_DURATION: float = 1.0 
const STUN_GETUP_FORWARD_DURATION: float = 0.5
const STUN_GETUP_BACKWARD_DURATION: float = 0.5
const STUN_GETUP_UP_DURATION: float = 0.4
const STUN_GETUP_DOWN_DURATION: float = 0.4

# Person | Knockout
const KNOCKOUT_DURATION: float = 2.0

# Fighter | Shield
const SHIELD_STUN_DURATION :float = 0.5
const ROLL_SHIELD_COST_RATIO : float = 0.1
const SHIELD_DURATION: float = 5.0
const SHIELD_REGENERATION_DURATION: float = 0.5

# Fighter | Grab
const GRAB_MOVE_SHORT_DURATION :float = 0.1
const GRAB_MOVE_NORMAL_DURATION :float = 0.3
const GRAB_MOVE_LONG_DURATION :float = 0.7
const GRAB_DURATION = 0.8
const GRABBING_COOLDOWN_DURATION :float = 0.5

# Fighter | Hitstun
const ABLE_TO_ATTACK_WITH_HITSTUN_DURATION :float = 0.5
