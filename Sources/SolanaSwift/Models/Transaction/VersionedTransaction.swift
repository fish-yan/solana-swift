//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.01.2023.
//

import Foundation
import TweetNacl

public enum TransactionVersion {
    case v0
    case legacy
}

public struct VersionedTransaction {
    public var message: VersionedMessage
    public internal(set) var signatures: [Data]

    public var version: TransactionVersion {
        message.value.version
    }

    public init(message: VersionedMessage, signatures: [Data]? = nil) {
        self.message = message

        if let signatures = signatures {
            self.signatures = signatures
        } else {
            var signatures: [Data] = []
            for _ in 0 ..< message.value.header.numRequiredSignatures {
                signatures.append(Constants.defaultSignature)
            }
            self.signatures = signatures
        }
    }

    public func serialize() throws -> Data {
        let serializedMessage = try message.value.serialize()

        let encodedSignaturesLength = Data.encodeLength(signatures.count)
        let signaturesData = signatures.reduce(Data(), +)

        var serializedTransaction: Data = .init()
        serializedTransaction.append(encodedSignaturesLength)
        serializedTransaction.append(signaturesData)
        serializedTransaction.append(serializedMessage)

        return serializedTransaction
    }

    public static func deserialize(data: Data) throws -> Self {
        var byteArray = BinaryReader(bytes: data.bytes)

        var signatures: [Data] = []
        let signaturesLength = try byteArray.decodeLength()
        for _ in 0 ..< signaturesLength {
            let signatureData = try byteArray.read(count: Constants.signatureLength)
            signatures.append(Data(signatureData))
        }

        let versionedMessage = try VersionedMessage.deserialize(data: Data(byteArray.bytes))

        return .init(message: versionedMessage, signatures: signatures)
    }

    public mutating func sign(signers: [Account]) throws {
        let messageData = try message.value.serialize()
        let signerPubkeys = message.value.staticAccountKeys.prefix(message.value.header.numRequiredSignatures)

        for signer in signers {
            guard let signerIndex = signerPubkeys.firstIndex(of: signer.publicKey) else {
                print("Cannot sign with non signer key \(signer.publicKey.base58EncodedString)")
                continue
            }
            signatures[signerIndex] = try NaclSign.signDetached(
                message: messageData,
                secretKey: signer.secretKey
            )
        }
    }

    public mutating func addSignature(publicKey: PublicKey, signature: Data) throws {
        let signerPubkeys = Array(message.value.staticAccountKeys.prefix(message.value.header.numRequiredSignatures))

        guard let signerIndex = signerPubkeys.firstIndex(of: publicKey) else {
            throw SolanaError.assertionFailed("Can not add signature because \(publicKey.base58EncodedString) is not required to sign this transaction")
        }

        signatures[signerIndex] = signature
    }
}
