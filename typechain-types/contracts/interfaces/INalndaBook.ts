/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumberish,
  BytesLike,
  FunctionFragment,
  Result,
  Interface,
  EventFragment,
  AddressLike,
  ContractRunner,
  ContractMethod,
  Listener,
} from "ethers";
import type {
  TypedContractEvent,
  TypedDeferredTopicFilter,
  TypedEventLog,
  TypedLogDescription,
  TypedListener,
  TypedContractMethod,
} from "../../common";

export interface INalndaBookInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "approve"
      | "approved"
      | "balanceOf"
      | "changeApproval"
      | "coverIdCounter"
      | "getApproved"
      | "isApprovedForAll"
      | "lastSoldPrice"
      | "marketplaceTransfer"
      | "ownedAt"
      | "ownerOf"
      | "safeTransferFrom(address,address,uint256)"
      | "safeTransferFrom(address,address,uint256,bytes)"
      | "secondarySalesTimestamp"
      | "setApprovalForAll"
      | "supportsInterface"
      | "transferFrom"
      | "updateLastSoldPrice"
      | "uri"
  ): FunctionFragment;

  getEvent(
    nameOrSignatureOrTopic: "Approval" | "ApprovalForAll" | "Transfer"
  ): EventFragment;

  encodeFunctionData(
    functionFragment: "approve",
    values: [AddressLike, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "approved", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "balanceOf",
    values: [AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "changeApproval",
    values: [boolean]
  ): string;
  encodeFunctionData(
    functionFragment: "coverIdCounter",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getApproved",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "isApprovedForAll",
    values: [AddressLike, AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "lastSoldPrice",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "marketplaceTransfer",
    values: [AddressLike, AddressLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "ownedAt",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "ownerOf",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "safeTransferFrom(address,address,uint256)",
    values: [AddressLike, AddressLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "safeTransferFrom(address,address,uint256,bytes)",
    values: [AddressLike, AddressLike, BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "secondarySalesTimestamp",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "setApprovalForAll",
    values: [AddressLike, boolean]
  ): string;
  encodeFunctionData(
    functionFragment: "supportsInterface",
    values: [BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "transferFrom",
    values: [AddressLike, AddressLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "updateLastSoldPrice",
    values: [BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "uri", values?: undefined): string;

  decodeFunctionResult(functionFragment: "approve", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "approved", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "balanceOf", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "changeApproval",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "coverIdCounter",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getApproved",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isApprovedForAll",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "lastSoldPrice",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "marketplaceTransfer",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "ownedAt", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "ownerOf", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "safeTransferFrom(address,address,uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "safeTransferFrom(address,address,uint256,bytes)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "secondarySalesTimestamp",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setApprovalForAll",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "supportsInterface",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferFrom",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "updateLastSoldPrice",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "uri", data: BytesLike): Result;
}

export namespace ApprovalEvent {
  export type InputTuple = [
    owner: AddressLike,
    approved: AddressLike,
    tokenId: BigNumberish
  ];
  export type OutputTuple = [owner: string, approved: string, tokenId: bigint];
  export interface OutputObject {
    owner: string;
    approved: string;
    tokenId: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace ApprovalForAllEvent {
  export type InputTuple = [
    owner: AddressLike,
    operator: AddressLike,
    approved: boolean
  ];
  export type OutputTuple = [
    owner: string,
    operator: string,
    approved: boolean
  ];
  export interface OutputObject {
    owner: string;
    operator: string;
    approved: boolean;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace TransferEvent {
  export type InputTuple = [
    from: AddressLike,
    to: AddressLike,
    tokenId: BigNumberish
  ];
  export type OutputTuple = [from: string, to: string, tokenId: bigint];
  export interface OutputObject {
    from: string;
    to: string;
    tokenId: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export interface INalndaBook extends BaseContract {
  connect(runner?: ContractRunner | null): INalndaBook;
  waitForDeployment(): Promise<this>;

  interface: INalndaBookInterface;

  queryFilter<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;
  queryFilter<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;

  on<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  on<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  once<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  once<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  listeners<TCEvent extends TypedContractEvent>(
    event: TCEvent
  ): Promise<Array<TypedListener<TCEvent>>>;
  listeners(eventName?: string): Promise<Array<Listener>>;
  removeAllListeners<TCEvent extends TypedContractEvent>(
    event?: TCEvent
  ): Promise<this>;

  approve: TypedContractMethod<
    [to: AddressLike, tokenId: BigNumberish],
    [void],
    "nonpayable"
  >;

  approved: TypedContractMethod<[], [boolean], "view">;

  balanceOf: TypedContractMethod<[owner: AddressLike], [bigint], "view">;

  changeApproval: TypedContractMethod<
    [_newApproved: boolean],
    [void],
    "nonpayable"
  >;

  coverIdCounter: TypedContractMethod<[], [bigint], "view">;

  getApproved: TypedContractMethod<[tokenId: BigNumberish], [string], "view">;

  isApprovedForAll: TypedContractMethod<
    [owner: AddressLike, operator: AddressLike],
    [boolean],
    "view"
  >;

  lastSoldPrice: TypedContractMethod<
    [_tokenId: BigNumberish],
    [bigint],
    "view"
  >;

  marketplaceTransfer: TypedContractMethod<
    [from: AddressLike, to: AddressLike, tokenId: BigNumberish],
    [void],
    "nonpayable"
  >;

  ownedAt: TypedContractMethod<[_tokenId: BigNumberish], [bigint], "view">;

  ownerOf: TypedContractMethod<[tokenId: BigNumberish], [string], "view">;

  "safeTransferFrom(address,address,uint256)": TypedContractMethod<
    [from: AddressLike, to: AddressLike, tokenId: BigNumberish],
    [void],
    "nonpayable"
  >;

  "safeTransferFrom(address,address,uint256,bytes)": TypedContractMethod<
    [
      from: AddressLike,
      to: AddressLike,
      tokenId: BigNumberish,
      data: BytesLike
    ],
    [void],
    "nonpayable"
  >;

  secondarySalesTimestamp: TypedContractMethod<[], [bigint], "view">;

  setApprovalForAll: TypedContractMethod<
    [operator: AddressLike, approved: boolean],
    [void],
    "nonpayable"
  >;

  supportsInterface: TypedContractMethod<
    [interfaceId: BytesLike],
    [boolean],
    "view"
  >;

  transferFrom: TypedContractMethod<
    [from: AddressLike, to: AddressLike, tokenId: BigNumberish],
    [void],
    "nonpayable"
  >;

  updateLastSoldPrice: TypedContractMethod<
    [_tokenId: BigNumberish, _price: BigNumberish],
    [void],
    "nonpayable"
  >;

  uri: TypedContractMethod<[], [void], "view">;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "approve"
  ): TypedContractMethod<
    [to: AddressLike, tokenId: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "approved"
  ): TypedContractMethod<[], [boolean], "view">;
  getFunction(
    nameOrSignature: "balanceOf"
  ): TypedContractMethod<[owner: AddressLike], [bigint], "view">;
  getFunction(
    nameOrSignature: "changeApproval"
  ): TypedContractMethod<[_newApproved: boolean], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "coverIdCounter"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "getApproved"
  ): TypedContractMethod<[tokenId: BigNumberish], [string], "view">;
  getFunction(
    nameOrSignature: "isApprovedForAll"
  ): TypedContractMethod<
    [owner: AddressLike, operator: AddressLike],
    [boolean],
    "view"
  >;
  getFunction(
    nameOrSignature: "lastSoldPrice"
  ): TypedContractMethod<[_tokenId: BigNumberish], [bigint], "view">;
  getFunction(
    nameOrSignature: "marketplaceTransfer"
  ): TypedContractMethod<
    [from: AddressLike, to: AddressLike, tokenId: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "ownedAt"
  ): TypedContractMethod<[_tokenId: BigNumberish], [bigint], "view">;
  getFunction(
    nameOrSignature: "ownerOf"
  ): TypedContractMethod<[tokenId: BigNumberish], [string], "view">;
  getFunction(
    nameOrSignature: "safeTransferFrom(address,address,uint256)"
  ): TypedContractMethod<
    [from: AddressLike, to: AddressLike, tokenId: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "safeTransferFrom(address,address,uint256,bytes)"
  ): TypedContractMethod<
    [
      from: AddressLike,
      to: AddressLike,
      tokenId: BigNumberish,
      data: BytesLike
    ],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "secondarySalesTimestamp"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "setApprovalForAll"
  ): TypedContractMethod<
    [operator: AddressLike, approved: boolean],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "supportsInterface"
  ): TypedContractMethod<[interfaceId: BytesLike], [boolean], "view">;
  getFunction(
    nameOrSignature: "transferFrom"
  ): TypedContractMethod<
    [from: AddressLike, to: AddressLike, tokenId: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "updateLastSoldPrice"
  ): TypedContractMethod<
    [_tokenId: BigNumberish, _price: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(nameOrSignature: "uri"): TypedContractMethod<[], [void], "view">;

  getEvent(
    key: "Approval"
  ): TypedContractEvent<
    ApprovalEvent.InputTuple,
    ApprovalEvent.OutputTuple,
    ApprovalEvent.OutputObject
  >;
  getEvent(
    key: "ApprovalForAll"
  ): TypedContractEvent<
    ApprovalForAllEvent.InputTuple,
    ApprovalForAllEvent.OutputTuple,
    ApprovalForAllEvent.OutputObject
  >;
  getEvent(
    key: "Transfer"
  ): TypedContractEvent<
    TransferEvent.InputTuple,
    TransferEvent.OutputTuple,
    TransferEvent.OutputObject
  >;

  filters: {
    "Approval(address,address,uint256)": TypedContractEvent<
      ApprovalEvent.InputTuple,
      ApprovalEvent.OutputTuple,
      ApprovalEvent.OutputObject
    >;
    Approval: TypedContractEvent<
      ApprovalEvent.InputTuple,
      ApprovalEvent.OutputTuple,
      ApprovalEvent.OutputObject
    >;

    "ApprovalForAll(address,address,bool)": TypedContractEvent<
      ApprovalForAllEvent.InputTuple,
      ApprovalForAllEvent.OutputTuple,
      ApprovalForAllEvent.OutputObject
    >;
    ApprovalForAll: TypedContractEvent<
      ApprovalForAllEvent.InputTuple,
      ApprovalForAllEvent.OutputTuple,
      ApprovalForAllEvent.OutputObject
    >;

    "Transfer(address,address,uint256)": TypedContractEvent<
      TransferEvent.InputTuple,
      TransferEvent.OutputTuple,
      TransferEvent.OutputObject
    >;
    Transfer: TypedContractEvent<
      TransferEvent.InputTuple,
      TransferEvent.OutputTuple,
      TransferEvent.OutputObject
    >;
  };
}
