// The 6 predefined V1 signal templates. Kept in one place shared by
// sendSignal (validation) and, conceptually, mirrored client-side in
// lib/models/signal_template.dart — no free text, ever.
export const SIGNAL_TEMPLATE_IDS = [
  "coeur",
  "je_taime",
  "tu_me_manques",
  "pensee_pour_toi",
  "calin",
  "bisou",
] as const;

export type SignalTemplateId = (typeof SIGNAL_TEMPLATE_IDS)[number];

export function isValidTemplateId(value: unknown): value is SignalTemplateId {
  return (
    typeof value === "string" &&
    (SIGNAL_TEMPLATE_IDS as readonly string[]).includes(value)
  );
}
