import Foundation
import Combine  /// <- import必要



struct CustomError: Error {
    let message: String
}


// Combineにおける値のポストと購読
// 値のポスト: Publisher
// 購読: Subscriber



// MARK: - CurrentValueSubject<型, Error>(型の初期値): Subject(つまりPublisher)
let valueSubject = CurrentValueSubject<Int, Never>(3)
/// : https://developer.apple.com/documentation/combine/currentvaluesubject
/// : 値をポストできたり、最後にポストした値を保持するので、RxのBehabiorSubjectに近い。（onErrorやonCompleteに該当するイベントも流れるからRelayではない）
/// : 購読されていない状態で値がポストされても保持する

/// 現在の値
print(valueSubject.value)
valueSubject.value = 1

/// sink
/// : CurrentValueSubjectを購読
valueSubject.sink { current in
    print("current: \(current)")
}

/// send(_:)
/// : CurrentValueSubjectに値をポスト
/// : 同じ値がsendされても発火する
/// : valueで値を変更しても発火する。sendとvalueの違いは？
/// : send()で変更した場合とvalueプロパティで変更した場合も同等の挙動
valueSubject.send(10)
valueSubject.value = 20



// MARK: - PassthroughSubject<型, Error>: Subject(つまりPublisher)
let passSubject = PassthroughSubject<Int, Never>()
/// : https://developer.apple.com/documentation/combine/passthroughsubject
/// : 値をポストするだけで、最後にポストした値は保持しない。RxのPublishSubjectに近い。（onErrorやonCompleteに該当するイベントも流れるからRelayではない）
/// : 購読されていない状態で値がポストされても無視する

passSubject.send(10)

passSubject.sink { newValue in
    print("newValue: \(newValue)")
}

passSubject.send(100)  // 「newValue: 100」のみ出力



// MARK: - Just()
let just = Just(1)
/// : 1回だけ値をポストするpublisher
/// : RxのJustと同じ使い方

/// output
/// : emitした値
print(just.output)



// MARK: - combineLatest
let combineLatest = just.combineLatest(valueSubject)
/// : 引数で受け取ったPublisherを購読して、自身と引数で受け取ったPublisherから受け取った出力をTuppleでポストする

combineLatest.sink { tupple in
    print("tupple: \(tupple)")
}

valueSubject.send(5)



// MARK: - Future<型, Error>
let future = Future<Int, Never> { promise in
    print("Future emit.")
    promise(.success(1))
}
/// : インスタンスを生成した時点でクロージャ内が実行される（購読していなくても処理が実行される）
/// : 値は1回しか受け取らずfinishするので、実質インスタンス生成時のみ。クロージャ内でPublisherを購読することで、RxのSingleと同様の挙動を実現できそう。

future.sink { promise in
    print("promise: \(promise)")
}

let futureSubject = CurrentValueSubject<Int, Never>(2)
var cancellables = [AnyCancellable]()  // RxのDisposeBag()に該当する。DisposeBag()と違ってvarで宣言する必要がある。
/// 偶数だったらsuccess, 奇数だったらfailureを返す`Future`
let futureAsSingle = Future<String, CustomError> { promise in
    futureSubject.sink { value in
        if value % 2 == 0 {
            print("post Success")  // NOTE: promise()以外の部分は複数回呼ばれる
            promise(.success("futureAsSingle: \(value)"))
        } else {
            promise(.failure(.init(message: "Not even value: \(value)")))
        }
    }.store(in: &cancellables)
}

futureAsSingle
    .sink(receiveCompletion: { promise in
        switch promise {
        case .failure(let error):
            print(error.message)
        case .finished:
            print("Successful complete")
        }
    },
          receiveValue: { value in
            print(value)
    })

futureSubject.send(10)



// MARK: - Deferred<Publisher>
let deferredJust = Deferred { () -> Just<String> in
    print("Deferred emit.")
    return Just("Tutorial Deferred")
}
/// : 購読されるまでクロージャ内の処理が実行されない
/// : RxのSingleの置き換えとしては`Deferred` でwrapした方が良さそう。

deferredJust.sink { deferred in
    print("deferredJust: \(deferred)")
}

let deferredSubject = CurrentValueSubject<Int, Never>(3)
let deferredAsSingle = Deferred {
    Future<String, CustomError> { promise in
        deferredSubject.sink { value in
            if value % 2 == 0 {
                print("post Success")
                promise(.success("deferredAsSingle: \(value)"))
            } else {
                print("post Failure")
                promise(.failure(.init(message: "Not even value: \(value)")))
            }
        }.store(in: &cancellables)
    }
}

deferredAsSingle
    .sink(receiveCompletion: { promise in
        switch promise {
        case .failure(let error):
            print(error.message)
        case .finished:
            print("Successful complete")
        }
    },
          receiveValue: { value in
            print(value)
    })

deferredSubject.send(10)
