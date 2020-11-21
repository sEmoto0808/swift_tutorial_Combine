import Combine

// MARK: - CurrentValueSubject<型, Error>(型の初期値)
let valueSubject = CurrentValueSubject<Int, Never>(3)
/// 現在の値
print(valueSubject.value)
valueSubject.value = 1

/// sink
/// : CurrentValueSubjectを購読
/// : sinkした時点で1回処理が実行されるから、CurrentValueSubjectはHot
valueSubject.sink { current in
    print("current: \(current)")
}

/// send
/// : CurrentValueSubjectに値をポスト
/// : 同じ値がsendされても発火する
/// : valueで値を変更しても発火する。sendとvalueの違いは？
valueSubject.send(10)
valueSubject.value = 20



// MARK: - Just()
let just = Just(1)
/// : 1回だけ値をポストするpublisher
/// : RxのJustと同じ使い方

/// output
/// : emitした値
print(just.output)



// MARK: - combineLatest
let publisher = just.combineLatest(valueSubject)
/// : 引数で受け取ったPublisherを購読して、自身と引数で受け取ったPublisherから受け取った出力をTuppleでポストする

publisher.sink { tupple in
    print("tupple: \(tupple)")
}

valueSubject.send(100)
