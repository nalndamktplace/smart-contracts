/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../common";

export interface NalndaAirdropInterface extends utils.Interface {
  functions: {
    "currentNalndaBalance()": FunctionFragment;
    "currentSlab()": FunctionFragment;
    "distributeTokensIfAny(address)": FunctionFragment;
    "isAirdropActive()": FunctionFragment;
    "maxAirdropTokens()": FunctionFragment;
    "nalndaToken()": FunctionFragment;
    "owner()": FunctionFragment;
    "renounceOwnership()": FunctionFragment;
    "tokensToDistributePerBook(uint8)": FunctionFragment;
    "transferOwnership(address)": FunctionFragment;
    "withdrawAllNalndaAndStopAirdrop()": FunctionFragment;
    "withdrawAnyEther()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "currentNalndaBalance"
      | "currentSlab"
      | "distributeTokensIfAny"
      | "isAirdropActive"
      | "maxAirdropTokens"
      | "nalndaToken"
      | "owner"
      | "renounceOwnership"
      | "tokensToDistributePerBook"
      | "transferOwnership"
      | "withdrawAllNalndaAndStopAirdrop"
      | "withdrawAnyEther"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "currentNalndaBalance",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "currentSlab",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "distributeTokensIfAny",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "isAirdropActive",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "maxAirdropTokens",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "nalndaToken",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "renounceOwnership",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "tokensToDistributePerBook",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawAllNalndaAndStopAirdrop",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawAnyEther",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "currentNalndaBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "currentSlab",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "distributeTokensIfAny",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isAirdropActive",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "maxAirdropTokens",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "nalndaToken",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "renounceOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "tokensToDistributePerBook",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawAllNalndaAndStopAirdrop",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawAnyEther",
    data: BytesLike
  ): Result;

  events: {
    "OwnershipTransferred(address,address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
}

export interface OwnershipTransferredEventObject {
  previousOwner: string;
  newOwner: string;
}
export type OwnershipTransferredEvent = TypedEvent<
  [string, string],
  OwnershipTransferredEventObject
>;

export type OwnershipTransferredEventFilter =
  TypedEventFilter<OwnershipTransferredEvent>;

export interface NalndaAirdrop extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: NalndaAirdropInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    currentNalndaBalance(overrides?: CallOverrides): Promise<[BigNumber]>;

    currentSlab(overrides?: CallOverrides): Promise<[number]>;

    distributeTokensIfAny(
      buyer: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    isAirdropActive(overrides?: CallOverrides): Promise<[boolean]>;

    maxAirdropTokens(overrides?: CallOverrides): Promise<[BigNumber]>;

    nalndaToken(overrides?: CallOverrides): Promise<[string]>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    renounceOwnership(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    tokensToDistributePerBook(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    withdrawAllNalndaAndStopAirdrop(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    withdrawAnyEther(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  currentNalndaBalance(overrides?: CallOverrides): Promise<BigNumber>;

  currentSlab(overrides?: CallOverrides): Promise<number>;

  distributeTokensIfAny(
    buyer: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  isAirdropActive(overrides?: CallOverrides): Promise<boolean>;

  maxAirdropTokens(overrides?: CallOverrides): Promise<BigNumber>;

  nalndaToken(overrides?: CallOverrides): Promise<string>;

  owner(overrides?: CallOverrides): Promise<string>;

  renounceOwnership(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  tokensToDistributePerBook(
    arg0: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  transferOwnership(
    newOwner: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  withdrawAllNalndaAndStopAirdrop(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  withdrawAnyEther(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    currentNalndaBalance(overrides?: CallOverrides): Promise<BigNumber>;

    currentSlab(overrides?: CallOverrides): Promise<number>;

    distributeTokensIfAny(
      buyer: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    isAirdropActive(overrides?: CallOverrides): Promise<boolean>;

    maxAirdropTokens(overrides?: CallOverrides): Promise<BigNumber>;

    nalndaToken(overrides?: CallOverrides): Promise<string>;

    owner(overrides?: CallOverrides): Promise<string>;

    renounceOwnership(overrides?: CallOverrides): Promise<void>;

    tokensToDistributePerBook(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    withdrawAllNalndaAndStopAirdrop(overrides?: CallOverrides): Promise<void>;

    withdrawAnyEther(overrides?: CallOverrides): Promise<void>;
  };

  filters: {
    "OwnershipTransferred(address,address)"(
      previousOwner?: PromiseOrValue<string> | null,
      newOwner?: PromiseOrValue<string> | null
    ): OwnershipTransferredEventFilter;
    OwnershipTransferred(
      previousOwner?: PromiseOrValue<string> | null,
      newOwner?: PromiseOrValue<string> | null
    ): OwnershipTransferredEventFilter;
  };

  estimateGas: {
    currentNalndaBalance(overrides?: CallOverrides): Promise<BigNumber>;

    currentSlab(overrides?: CallOverrides): Promise<BigNumber>;

    distributeTokensIfAny(
      buyer: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    isAirdropActive(overrides?: CallOverrides): Promise<BigNumber>;

    maxAirdropTokens(overrides?: CallOverrides): Promise<BigNumber>;

    nalndaToken(overrides?: CallOverrides): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    renounceOwnership(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    tokensToDistributePerBook(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    withdrawAllNalndaAndStopAirdrop(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    withdrawAnyEther(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    currentNalndaBalance(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    currentSlab(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    distributeTokensIfAny(
      buyer: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    isAirdropActive(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    maxAirdropTokens(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    nalndaToken(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    renounceOwnership(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    tokensToDistributePerBook(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    withdrawAllNalndaAndStopAirdrop(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    withdrawAnyEther(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}