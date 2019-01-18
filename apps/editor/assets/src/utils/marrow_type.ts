enum BaseType {
  String = "string",
  Bool = "bool",
  Int = "int",
  Role = "role",
  Tile = "tile",
  Atom = "atom",
  Any = "any"
}

interface Base {
  kind: "base";
  type: BaseType;
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

type MarrowType = Base | Or | List | Identifier | Pair;

const Types = {
  int(): Base {
    return { kind: "base", type: BaseType.Int };
  },

  string(): Base {
    return { kind: "base", type: BaseType.String };
  },

  bool(): Base {
    return { kind: "base", type: BaseType.Bool };
  },

  tile(): Base {
    return { kind: "base", type: BaseType.Tile };
  },

  role(): Base {
    return { kind: "base", type: BaseType.Role };
  },

  atom(): Base {
    return { kind: "base", type: BaseType.Atom };
  },

  any(): Base {
    return { kind: "base", type: BaseType.Any };
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
    case "base":
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
