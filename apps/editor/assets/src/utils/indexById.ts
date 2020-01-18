export default function indexById(objects: { id: any }[]) {
  return objects.reduce((current, acc) => ({ ...current, [acc.id]: acc }), {});
}
