package main


/*
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

import (
	"fmt"
	"github.com/hyperledger/fabric/bccsp"
	"github.com/hyperledger/fabric/bccsp/factory"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/core/chaincode/shim/ext/entities"
	pb "github.com/hyperledger/fabric/protos/peer"

)

const ENCKEY = "ENCKEY"

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
	bccspInst bccsp.BCCSP
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("gm crypt test chaincode Init")
	_, args := stub.GetFunctionAndParameters()
	// Write the state to the ledger
	A:=args[0]

	err := stub.PutState(A,[]byte(args[1]) )
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("gm crypt test chaincode Invoke")
	function, args := stub.GetFunctionAndParameters()

	if function == "invoke" {
		// Make payment of X units from A to B
		return t.invoke(stub, args)
	} else if function == "query" {
		// the old "Query" is now implemtned in invoke
		return t.query(stub, args)
	} else if function == "crypt_invoke"{
		tMap, err := stub.GetTransient()
		if err != nil {
			return shim.Error(fmt.Sprintf("Could not retrieve transient, err %s", err))
		}
		if _, in := tMap[ENCKEY]; !in {
			return shim.Error(fmt.Sprintf("Expected transient encryption key %s", ENCKEY))
		}
		return t.cryptInvoke(stub,args,tMap[ENCKEY])
	}else if function == "crypt_query"{
		tMap, err := stub.GetTransient()
		if err != nil {
			return shim.Error(fmt.Sprintf("Could not retrieve transient, err %s", err))
		}
		if _, in := tMap[ENCKEY]; !in {
			return shim.Error(fmt.Sprintf("Expected transient encryption key %s", ENCKEY))
		}
		return t.cryptQuery(stub,args,tMap[ENCKEY])
	}

	return shim.Error("Invalid invoke function name. Expecting \"invoke\" \"crypt_invoke\" \"crypt_query\"")
}

// simpple write ledger
func (t *SimpleChaincode) invoke(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var A, B string    // Entities
	var err error

	if len(args) != 2 {
		return shim.Error("invoke Incorrect number of arguments. Expecting 2")
	}

	A = args[0]
	B = args[1]


	// Write the state back to the ledger
	err = stub.PutState(A, []byte(B))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}



// query callback representing the query of a chaincode
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var A string // Entities
	var err error

	if len(args) != 1 {
		return shim.Error("query Incorrect number of arguments. Expecting name of the person to query")
	}

	A = args[0]

	// Get the state from the ledger
	Avalbytes, err := stub.GetState(A)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	if Avalbytes == nil {
		jsonResp := "{\"Error\":\"Nil amount for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	jsonResp := "{\"Name\":\"" + A + "\",\"Amount\":\"" + string(Avalbytes) + "\"}"
	fmt.Printf("Query Response:%s\n", jsonResp)
	return shim.Success(Avalbytes)
}




func (t *SimpleChaincode) cryptInvoke(stub shim.ChaincodeStubInterface, args []string, encKey []byte) pb.Response {
	// create the encrypter entity - we give it an ID, the bccsp instance, the key and (optionally) the IV
	ent, err := entities.NewSM4EncrypterEntity("ID", t.bccspInst, encKey, nil)
	if err != nil {
		return shim.Error(fmt.Sprintf("entities.NewSM4EncrypterEntity failed, err %s", err))
	}

	if len(args) != 2 {
		return shim.Error("Expected 2 parameters to function Encrypter")
	}

	key := args[0]
	cleartextValue := []byte(args[1])

	// here, we encrypt cleartextValue and assign it to key
	err = encryptAndPutState(stub, ent, key, cleartextValue)
	if err != nil {
		return shim.Error(fmt.Sprintf("encryptAndPutState failed, err %+v", err))
	}
	return shim.Success(nil)
}

func encryptAndPutState(stub shim.ChaincodeStubInterface, ent entities.Encrypter, key string, value []byte) error {
	// at first we use the supplied entity to encrypt the value
	ciphertext, err := ent.Encrypt(value)
	if err != nil {
		return err
	}

	return stub.PutState(key, ciphertext)
}

func (t *SimpleChaincode) cryptQuery(stub shim.ChaincodeStubInterface, args []string, decKey []byte) pb.Response {
	// create the encrypter entity - we give it an ID, the bccsp instance, the key and (optionally) the IV
	ent, err := entities.NewSM4EncrypterEntity("ID", t.bccspInst, decKey,nil)
	if err != nil {
		return shim.Error(fmt.Sprintf("entities.NewSM4EncrypterEntity failed, err %s", err))
	}

	if len(args) != 1 {
		return shim.Error("Expected 1 parameters to function Decrypter")
	}

	key := args[0]

	// here we decrypt the state associated to key
	cleartextValue, err := getStateAndDecrypt(stub, ent, key)
	if err != nil {
		return shim.Error(fmt.Sprintf("getStateAndDecrypt failed, err %+v", err))
	}

	// here we return the decrypted value as a result
	return shim.Success(cleartextValue)
}

func getStateAndDecrypt(stub shim.ChaincodeStubInterface, ent entities.Encrypter, key string) ([]byte, error) {
	// at first we retrieve the ciphertext from the ledger
	ciphertext, err := stub.GetState(key)
	if err != nil {
		return nil, err
	}

	// GetState will return a nil slice if the key does not exist.
	// Note that the chaincode logic may want to distinguish between
	// nil slice (key doesn't exist in state db) and empty slice
	// (key found in state db but value is empty). We do not
	// distinguish the case here
	if len(ciphertext) == 0 {
		return nil, fmt.Errorf("no ciphertext to decrypt")
	}

	return ent.Decrypt(ciphertext)
}

func main(){
	factory.InitFactories(nil)
	err:=shim.Start(&SimpleChaincode{factory.GetDefault()})
	if err !=nil{
		fmt.Printf("Error starting gm encrypt test chaincode, %s",err)
	}
}