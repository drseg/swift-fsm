enum BuilderObjects<S, E> {
    struct Given {}
}

protocol Builder { }

extension Builder {
    typealias G = BuilderObjects<String, String>.Given
}
