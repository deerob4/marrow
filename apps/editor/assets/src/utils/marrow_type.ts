enum ScalarType {
  String = "string",
  Bool = "bool",
  Int = "int",
  Role = "role",
  Tile = "tile",
  Atom = "atom",
  Any = "any"
}

interface Scalar {
  kind: "scalar";
  type: ScalarType;
}

interface Or {
  kind: "or";
  types: MarrowType[];
}

interface List {
  kind: "list";
  type: MarrowType;
}

interface Identifier {
  kind: "identifier";
  value: string;
}

interface Pair {
  kind: "pair";
  first: MarrowType;
  second: MarrowType;
}

type MarrowType = Scalar | Or | List | Identifier | Pair;

const Types = {
  int(): Scalar {
    return { kind: "scalar", type: ScalarType.Int };
  },

  string(): Scalar {
    return { kind: "scalar", type: ScalarType.String };
  },

  bool(): Scalar {
    return { kind: "scalar", type: ScalarType.Bool };
  },

  tile(): Scalar {
    return { kind: "scalar", type: ScalarType.Tile };
  },

  role(): Scalar {
    return { kind: "scalar", type: ScalarType.Role };
  },

  atom(): Scalar {
    return { kind: "scalar", type: ScalarType.Atom };
  },

  any(): Scalar {
    return { kind: "scalar", type: ScalarType.Any };
  },

  list(type: MarrowType): List {
    return { kind: "list", type };
  },

  identifier(value: string): Identifier {
    return { kind: "identifier", value };
  },

  pair(first: MarrowType, second: MarrowType): Pair {
    return { kind: "pair", first, second };
  },

  or(types: MarrowType[]): Or {
    return { kind: "or", types };
  }
};

function typeToString(type: MarrowType): string {
  switch (type.kind) {
    case "scalar":
      return type.type;
    case "identifier":
      return type.value;
    case "list":
      return `[${typeToString(type.type)}]`;
    case "pair":
      return `(${typeToString(type.first)} ${typeToString(type.second)})`;
    case "or":
      return type.types.map(typeToString).join(" | ");
  }
}

function formatFunction(args: MarrowType[], returnType: MarrowType) {
  return args.map(typeToString).join("->") + "->" + typeToString(returnType);
}

function formatArgList(args: MarrowType[]) {
  return `(${args.map(typeToString).join(", ")})`;
}

export { MarrowType, Types, typeToString, formatFunction, formatArgList };
