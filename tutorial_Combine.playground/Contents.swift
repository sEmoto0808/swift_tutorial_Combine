import Foundation
import Combine  /// <- import必要



struct CustomError: Error {
    let message: String
}



// MARK: - CurrentValueSubject<型, Error>(型の初期値)
let valueSubject = CurrentValueSubject<Int, Never>(3)
/// : 値をポストできたり、現在の値を取得できたりするので、RxのBehabiorRelayに近い。

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
