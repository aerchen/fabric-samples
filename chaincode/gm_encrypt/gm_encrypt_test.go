package main

import (
	"bytes"
	"github.com/hyperledger/fabric/bccsp/factory"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/stretchr/testify/assert"
	"testing"
)

const AESKEY1   = "0123456789012345"

//func TestInit(t *testing.T) {
//	factory.InitFactories(nil)
//
//	scc := new(SimpleChaincode)
//	stub := shim.NewMockStub("enccc", scc)
//	stub.MockTransactionStart("a")
//	res := scc.Init(stub)
//	stub.MockTransactionEnd("a")
//	assert.Equal(t, res.Status, int32(shim.OK))
//}

func TestEnc(t *testing.T) {
	factory.InitFactories(nil)

	scc := &SimpleChaincode{factory.GetDefault()}
	stub := shim.NewMockStub("enccc", scc)

	// success
	stub.MockTransactionStart("a")
	res := scc.cryptInvoke(stub, []string{"key", "value"}, []byte(AESKEY1))
	stub.MockTransactionEnd("a")
	assert.Equal(t, res.Status, int32(shim.OK))

	//// fail - bad key
	//stub.MockTransactionStart("a")
	//res = scc.Encrypter(stub, []string{"key", "value"}, []byte("badkey"), nil)
	//stub.MockTransactionEnd("a")
	//assert.NotEqual(t, res.Status, int32(shim.OK))
	//
	//// fail - not enough args
	//stub.MockTransactionStart("a")
	//res = scc.Encrypter(stub, []string{"key"}, []byte(AESKEY1), nil)
	//stub.MockTransactionEnd("a")
	//assert.NotEqual(t, res.Status, int32(shim.OK))
	//
	// success
	stub.MockTransactionStart("a")
	res = scc.cryptQuery(stub, []string{"key"}, []byte(AESKEY1))
	stub.MockTransactionEnd("a")
	assert.Equal(t, res.Status, int32(shim.OK))
	assert.True(t, bytes.Equal(res.Payload, []byte("value")))
	//
	//// fail - not enough args
	//stub.MockTransactionStart("a")
	//res = scc.Decrypter(stub, []string{}, []byte(AESKEY1), nil)
	//stub.MockTransactionEnd("a")
	//assert.NotEqual(t, res.Status, int32(shim.OK))
	//
	//// fail - bad kvs key
	//stub.MockTransactionStart("a")
	//res = scc.Decrypter(stub, []string{"badkey"}, []byte(AESKEY1), nil)
	//stub.MockTransactionEnd("a")
	//assert.NotEqual(t, res.Status, int32(shim.OK))
	//
	//// fail - bad key
	//stub.MockTransactionStart("a")
	//res = scc.Decrypter(stub, []string{"key"}, []byte(AESKEY2), nil)
	//stub.MockTransactionEnd("a")
	//assert.NotEqual(t, res.Status, int32(shim.OK))
}

