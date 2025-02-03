import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures ownership transfer works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;
    const wallet2 = accounts.get("wallet_2")!;

    // Register product
    let block = chain.mineBlock([
      Tx.contractCall("farmo-registry", "register-product", 
        [types.utf8("Test Product"), types.utf8("Test Origin")], deployer.address)
    ]);
    assertEquals(block.receipts[0].result.expectOk(), "u1");

    // Transfer ownership
    block = chain.mineBlock([
      Tx.contractCall("farmo-transfer", "transfer-ownership",
        ["u1", types.principal(wallet1.address)], deployer.address)
    ]);
    assertEquals(block.receipts[0].result.expectOk(), true);

    // Verify ownership change
    block = chain.mineBlock([
      Tx.contractCall("farmo-registry", "get-product-owner",
        ["u1"], deployer.address)
    ]);
    assertEquals(block.receipts[0].result.expectOk(), wallet1.address);
  }
});

Clarinet.test({
  name: "Validates transfer event logging",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("farmo-transfer", "log-transfer-event",
        ["u1", types.ascii("completed")], deployer.address)
    ]);
    assertEquals(block.receipts[0].result.expectOk(), "u1");
  }
});
