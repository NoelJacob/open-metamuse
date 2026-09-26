# Aura color table — light plus dark per surface

Sole source of hex: `scripts/decode_colors.py` (assert-checked decode of
`BaseColors.java`, `AuraColorsPaletteKt.java`, `HatchConversationTheme.java`).
`Source` cites the decompiled file plus field, or `screenshot-sampled` for
display-verified fills. Cells marked `unverified — confirm first` have no
decompiled or screenshot grounding yet.

Decision: chat screens use conversation tokens (`HatchConversationTheme`
`DEFAULT`), everything else uses surface tokens (`auraColorsLight/Dark`).
Chat background (`#FFF5F5F5`/`#FF1A1A1A`) differs from app surface background
(`#FFFCFCFC`/`#FF050505`).

## Surfaces

| Surface | Light | Dark | Source |
|---|---|---|---|
| App background (surface.background) | `#FFFCFCFC` | `#FF050505` | AuraColorsPaletteKt light/dark surface arg 1; screenshot-sampled both (`#FFFCFCFC`, `#FF050505` full-band) |
| Chat background (painted canvas) | `#FFFCFCFC` | `#FF050505` | screenshot-sampled full-band both modes (1080px runs at y=700) |
| Chat background (conversation default, unpainted) | `#FFF5F5F5` | `#FF1A1A1A` | HatchConversationTheme DEFAULT args 1-2 (j4 literal 4294309365, 4279900698); overridden by painted canvas in both modes |
| User bubble | `#FF000000` | `#FFFFFFFF` | HatchConversationTheme DEFAULT args 3-4 (AMB.A01, AMB.A08); screenshot-sampled both (`#FF000000` 502px run, `#FFFFFFFF` 528px run) |
| User text | `#FFFFFFFF` | `#FF111112` | HatchConversationTheme DEFAULT args 7-8 (j6=AMB.A08, j7=GRAY_1100 4279308562); dark verified on white bubble in dark screenshot |
| Agent bubble | `#FFE9EAEB` | `#FF1F1F1F` | HatchConversationTheme DEFAULT args 5-6 (GRAY_100 4293520107, j3 literal 4280229663); screenshot-sampled both (917px / 609px runs) |
| Agent text | `#FF111112` | `#FFF5F5F5` | HatchConversationTheme DEFAULT args 9-10 (j7, j4); light glyph cores `#FF111112` screenshot-sampled |
| Quote card fill | `#FFE9EAEB` | `#FF1F1F1F` | surface.bubble both modes; screenshot-sampled light 917px bands y=970-1000; dark same-band as agent fill |
| Reply attribution text | `#99000409` | `#66F1F6FF` | AuraColorsPaletteKt jA05 (near-black 60% over quote) / jA09 (near-white 40% over card); light composite `#5D5E5E` matches sampled `#5D6063` ramp |
| Primary button bg | `#FF0064D4` | `#FF007FFD` | AuraColorsPaletteKt light/dark ButtonColors arg 3 (4278215892, 4278222845) |
| Primary button text | `#FFFFFFFF` | `#FF000000` | AuraColorsPaletteKt ButtonColors invertedButtonContent (WHITE light, BLACK dark) |
| Brand blue (links, resend, icons) | `#FF0064E0` | `#FF0064E0` | BaseColors.BLUE_650 4278215904, both modes |
| Destructive button bg | `#FFC01F37` | `#FFE7354A` | AuraColorsPaletteKt ButtonColors arg 4 (RED_650 4290780983, 4293342538) |
| Secondary pill bg | `#FFF3F4F5` | `#FF1F1F1F` | AuraColorsPaletteKt buttonSecondaryBackground (GRAY_50 light, GRAY_1050 dark = D_card) |
| Settings card fill | `#FFFFFFFF` | `#FF1F1F1F` | AuraColorsPaletteKt surface.card (WHITE light, j25 literal 4280229663 dark) |
| Elevated surface | `#FFEEEFF0` | `#FF343638` | AuraColorsPaletteKt surface.secondaryElevated light (4293849072); dark elevated 4281611832 |
| Dialog/modal surface | `#FFFFFFFF` | `#FF1F1F1F` | AuraColorsPaletteKt surface.modal (WHITE light, GRAY_1050 dark); secondaryModal same dark |
| Divider | `#1A000000` | `#1FFFFFFF` | AuraColorsPaletteKt BorderColors divider (436207616 light, 536870911 dark) |
| Border (OTP boxes, text fields) | `#FF343434` | `#FFA1A1A1` | AuraColorsPaletteKt BorderColors unfocusedBorder 4281611316 light; dark focusedBorder `4288782753` |
| Primary text | `#FF111112` | `#FFF5F5F5` | AuraColorsPaletteKt TextAndIconColors textPrimary (4279308562, 4294309365); light glyph-sampled |
| Secondary text | `#99000409` | `#99F2F7FF` | AuraColorsPaletteKt jA05/jA08 blends (near-black 60% / near-white 60%) |
| Tertiary text | `#59000711` | `#66F1F6FF` | AuraColorsPaletteKt jA06/jA09 blends (near-black 35% / near-white 40%) |
| Quaternary text (dark only sampled) | `#4A000814` | `#4FF0F6FF` | AuraColorsPaletteKt jA07 light blend (near-black 29%) / dark j31 inline blend (near-white 31%) |
| Hint / placeholder | `#FFA1A4A8` | `#FFA1A1A1` | BaseColors.GRAY_400 4288783528 light; dark `4288782753` literal |
| Cursor | `#FF638FFF` | `#FF638FFF` | AuraColorsPaletteKt FeatureColors cursor (4284715007, both modes) |
| Error text / bg | `#FFFF453A` / `#FFFF3040` | `#FFFF6877` / `#FFFF3040` | AuraColorsPaletteKt SemanticColors error 4294919482 light, RED_450 4294928503 dark; badge 4294914112 both |
| Success | `#FF25B159` | `#FF00EA57` | AuraColorsPaletteKt SemanticColors success (4280660313, 4278250071) |
| Success icon | `#FF008200` | `#FF008200` | AuraColorsPaletteKt SemanticColors iconSuccess 4278223360 both modes |
| Inactive / disabled | `#FF8E8E93` | `#FF8E8E93` | AuraColorsPaletteKt SemanticColors inactive 4287532691 both modes |
| Negative accent | `#FFF05F69` | `#FFF05F69` | AuraColorsPaletteKt SemanticColors negativeAccent 4293943145 both modes |
| Scrim | `#4D000000` | `#80000000` | AuraColorsPaletteKt surface.scrim (1291845632 light, 2147483648 dark) |
| Shadow | `#33000000` | `#33000000` | AuraColorsPaletteKt black 20% blend both modes |
| Toast fill / text | `unverified` | `unverified` | no palette read located toast tokens; do not consume for theme |
| Shimmer base / highlight | `#FFDCE0E5` / `#FFF1F4F7` | `#FF1C2B33` / `#FF30424B` | AuraColorsPaletteKt surface.shimmeringBase/Highlight (4292665573/4294046967 light, 4280036147/4281352779 dark) |
| Avatar border | `#0F000000` | `#0FFFFFFF` | AuraColorsPaletteKt BorderColors avatarBorder (251658240 light, 268435455 dark) |
| Tab selected / unselected | `#FF000000` / `unverified` | `#FFFFFFFF` / `unverified` | selected screenshot-sampled; unselected token not located — do not consume for theme |
| Switch track on / off | `unverified` | `unverified` | switch tokens not located; mirrored fills removed as guesses — do not consume for theme |
| Notification badge | `#FFFF3040` | `#FFFF3040` | AuraColorsPaletteKt FeatureColors notificationBadge 4294914112 both modes |
| Composer pill fill | `#FFE9EAEB` | `#FF1F1F1F` | surface.bubble (AuraColorsPaletteKt; light disambiguates: card would be `#FFFFFFFF`, scan shows `#FFE9EAEB`; dark ambiguous, j25 feeds card and bubble identically); wide runs light 976px + dark 976px |
| Menu popover fill | `unverified` | `unverified` | no flat-fill sample yet — do not consume for theme |
| Date divider text | `#99000409` | `#99F2F7FF` | same tokens as Secondary text row; ramp consistent in screenshots |
| Link / accent text | `#FF0064E0` | `unverified` | light is brand BLUE_650; dark guessed cursor-blue removed — do not consume for theme |
