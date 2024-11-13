//
//  ComputeBudgetProgram.swift
//  SolanaSwift
//
//  Created by yan on 13/11/24.
//

import Foundation

public enum ComputeBudgetProgram: SolanaBasicProgram {
    private enum Index: UInt8, BytesEncodable {
        case SetComputeUnitLimit = 2
        case SetComputeUnitPrice = 3
    }
    
    public static var id: PublicKey {
        "ComputeBudget111111111111111111111111111111"
    }
    
    public static func computeUnitLimitInstruction(units: UInt64) -> TransactionInstruction {
        return TransactionInstruction(
            keys: [],
            programId: ComputeBudgetProgram.id,
            data: [Index.SetComputeUnitLimit, units]
        )
    }
    
    public static func computeUnitPriceInstruction(microLamports: UInt64) -> TransactionInstruction {
        return TransactionInstruction(
            keys: [],
            programId: ComputeBudgetProgram.id,
            data: [Index.SetComputeUnitPrice, microLamports]
        )
    }
}
