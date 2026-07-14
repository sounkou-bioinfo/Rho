#' Message content and tool contracts
#'
#' Messages contain typed content objects rather than discriminator strings.
#' Tool execution is asynchronous, and overlap is represented by an S7 value
#' that the agent can dispatch on.
#'
#' @name rho_ai_messages
#' @aliases TextContent ThinkingContent ImageContent ArtifactRefContent ToolCall
#' @aliases UserMessage AssistantMessage ToolResultMessage ToolOverlap
#' @aliases ToolMayOverlap ToolRequiresExclusiveExecution ToolSpec ToolResult
#' @aliases ToolErrorResult Tool rho_text rho_thinking rho_user_message
#' @aliases rho_assistant_message rho_tool_result_message rho_tool_spec
#' @aliases rho_tool_result rho_tool_error_result rho_validate_tool_args
#' @aliases rho_execute_tool rho_tool_overlap
#' @export TextContent
#' @export ThinkingContent
#' @export ImageContent
#' @export ArtifactRefContent
#' @export ToolCall
#' @export UserMessage
#' @export AssistantMessage
#' @export ToolResultMessage
#' @export ToolOverlap
#' @export ToolMayOverlap
#' @export ToolRequiresExclusiveExecution
#' @export ToolSpec
#' @export ToolResult
#' @export ToolErrorResult
#' @export Tool
#' @export rho_text
#' @export rho_thinking
#' @export rho_user_message
#' @export rho_assistant_message
#' @export rho_tool_result_message
#' @export rho_tool_spec
#' @export rho_tool_result
#' @export rho_tool_error_result
#' @export rho_validate_tool_args
#' @export rho_execute_tool
#' @export rho_tool_overlap
NULL

#' Normalized token usage and pricing
#'
#' Usage components are disjoint: `input` excludes cache reads and writes,
#' while `output` includes any reported reasoning tokens. `reasoning` is an
#' optional breakdown of `output`; it is never added to `total` a second time.
#' The optional `cache_write_1h` value is a subset of `cache_write`.
#'
#' `rho_price_usage()` is the open pricing protocol. Its default `Model`
#' method selects the highest matching long-context tier, prices every
#' component, and returns a new `Usage` value. Model subclasses may provide
#' methods for provider-specific pricing rules.
#'
#' @name rho_ai_usage
#' @aliases Usage UsageCost rho_usage rho_usage_cost rho_price_usage
#' @export Usage
#' @export UsageCost
#' @export rho_usage
#' @export rho_usage_cost
#' @export rho_price_usage
NULL

#' Typed OpenAI Responses request composition
#'
#' OpenAI request bodies are reductions over typed sections. Model-specific
#' methods select the sections and their defaults; section methods alone emit
#' wire field names and provider values. Extensions can specialize
#' `rho_openai_request_sections()` for a model subclass or append a new
#' `OpenAIRequestSection` with a `rho_openai_request_fields()` method.
#'
#' Canonical thinking requests are values. `ThinkingOff` therefore dispatches
#' separately from enabled levels without comparing provider wire strings.
#'
#' @name rho_openai_request_policy
#' @aliases ThinkingRequest ThinkingUnspecified ThinkingLevel ThinkingOff
#' @aliases ThinkingEnabled rho_thinking_level OpenAIRequestSection
#' @aliases OpenAIOmittedRequestSection OpenAIRequestSectionProtocol
#' @aliases rho_openai_request_sections
#' @aliases rho_openai_request_fields rho_openai_reasoning_section
#' @aliases rho_openai_standard_request_sections
#' @export ThinkingRequest
#' @export ThinkingUnspecified
#' @export ThinkingLevel
#' @export ThinkingOff
#' @export ThinkingEnabled
#' @export rho_thinking_level
#' @export OpenAIRequestSection
#' @export OpenAIOmittedRequestSection
#' @export OpenAIRequestSectionProtocol
#' @export rho_openai_request_sections
#' @export rho_openai_request_fields
#' @export rho_openai_reasoning_section
#' @export rho_openai_standard_request_sections
NULL

#' OpenAI-compatible Chat Completions stream protocol
#'
#' Chat Completions chunks are parsed into typed wire values and reduced by S7
#' methods to the normalized `AssistantEvent` protocol.
#'
#' @name rho_openai_chat_wire
#' @aliases OpenAIChatCompletionsDecoder OpenAIChatWireEvent OpenAIChatIgnored
#' @aliases OpenAIChatThinkingDelta OpenAIChatTextDelta OpenAIChatToolDelta
#' @aliases OpenAIChatFinishSignal OpenAIChatUsageUpdate OpenAIChatDone
#' @aliases OpenAIChatError rho_openai_chat_decoder rho_openai_chat_message
#' @export OpenAIChatCompletionsDecoder
#' @export OpenAIChatWireEvent
#' @export OpenAIChatIgnored
#' @export OpenAIChatThinkingDelta
#' @export OpenAIChatTextDelta
#' @export OpenAIChatToolDelta
#' @export OpenAIChatFinishSignal
#' @export OpenAIChatUsageUpdate
#' @export OpenAIChatDone
#' @export OpenAIChatError
#' @export rho_openai_chat_decoder
#' @export rho_openai_chat_message
NULL

#' Z.ai provider
#'
#' Z.ai uses the OpenAI-compatible Chat Completions protocol with explicit
#' thinking preservation and tool-call streaming policies.
#'
#' @name rho_zai
#' @aliases ThinkingControl ZaiThinkingControl ToolCallStreamingPolicy
#' @aliases BufferedToolCallStreaming ZaiToolCallStreaming
#' @aliases ZaiChatCompletionsModel ZaiEndpoint ZaiCodingEndpoint
#' @aliases ZaiGeneralEndpoint ZaiApi ZaiApiKeyAuth
#' @aliases rho_zai_coding_endpoint rho_zai_china_coding_endpoint
#' @aliases rho_zai_general_endpoint rho_zai_model rho_zai_provider
#' @aliases rho_zai_request rho_apply_thinking_control
#' @aliases rho_apply_tool_call_streaming
#' @export ThinkingControl
#' @export ZaiThinkingControl
#' @export ToolCallStreamingPolicy
#' @export BufferedToolCallStreaming
#' @export ZaiToolCallStreaming
#' @export ZaiChatCompletionsModel
#' @export ZaiEndpoint
#' @export ZaiCodingEndpoint
#' @export ZaiGeneralEndpoint
#' @export ZaiApi
#' @export ZaiApiKeyAuth
#' @export rho_zai_coding_endpoint
#' @export rho_zai_china_coding_endpoint
#' @export rho_zai_general_endpoint
#' @export rho_zai_model
#' @export rho_zai_provider
#' @export rho_zai_request
#' @export rho_apply_thinking_control
#' @export rho_apply_tool_call_streaming
NULL

#' Normalized assistant and provider event protocols
#'
#' Providers emit the typed `AssistantEvent` hierarchy. Provider-specific wire
#' events are decoded and reduced through separate S7 generics, keeping wire
#' formats out of the agent loop.
#'
#' @name rho_ai_events
#' @aliases AssistantEvent AssistantPartialEvent AssistantStartEvent
#' @aliases AssistantUpdateEvent AssistantTextStartEvent AssistantTextDeltaEvent
#' @aliases AssistantTextEndEvent AssistantThinkingStartEvent
#' @aliases AssistantThinkingDeltaEvent AssistantThinkingEndEvent
#' @aliases AssistantToolCallStartEvent AssistantToolCallDeltaEvent
#' @aliases AssistantToolCallEndEvent AssistantTerminalEvent AssistantDoneEvent
#' @aliases AssistantErrorEvent ProviderEventDecoder ProviderWireEvent
#' @aliases ResponseItemProtocol rho_assistant_start_event
#' @aliases rho_assistant_text_start_event rho_assistant_text_delta_event
#' @aliases rho_assistant_text_end_event rho_assistant_thinking_start_event
#' @aliases rho_assistant_thinking_delta_event rho_assistant_thinking_end_event
#' @aliases rho_assistant_tool_call_start_event
#' @aliases rho_assistant_tool_call_delta_event rho_assistant_tool_call_end_event
#' @aliases rho_assistant_done_event rho_assistant_error_event
#' @aliases rho_assistant_event_type rho_decode_provider_event
#' @aliases rho_reduce_provider_event rho_start_response_item
#' @aliases rho_finish_response_item
#' @export AssistantEvent
#' @export AssistantPartialEvent
#' @export AssistantStartEvent
#' @export AssistantUpdateEvent
#' @export AssistantTextStartEvent
#' @export AssistantTextDeltaEvent
#' @export AssistantTextEndEvent
#' @export AssistantThinkingStartEvent
#' @export AssistantThinkingDeltaEvent
#' @export AssistantThinkingEndEvent
#' @export AssistantToolCallStartEvent
#' @export AssistantToolCallDeltaEvent
#' @export AssistantToolCallEndEvent
#' @export AssistantTerminalEvent
#' @export AssistantDoneEvent
#' @export AssistantErrorEvent
#' @export ProviderEventDecoder
#' @export ProviderWireEvent
#' @export ResponseItemProtocol
#' @export rho_assistant_start_event
#' @export rho_assistant_text_start_event
#' @export rho_assistant_text_delta_event
#' @export rho_assistant_text_end_event
#' @export rho_assistant_thinking_start_event
#' @export rho_assistant_thinking_delta_event
#' @export rho_assistant_thinking_end_event
#' @export rho_assistant_tool_call_start_event
#' @export rho_assistant_tool_call_delta_event
#' @export rho_assistant_tool_call_end_event
#' @export rho_assistant_done_event
#' @export rho_assistant_error_event
#' @export rho_assistant_event_type
#' @export rho_decode_provider_event
#' @export rho_reduce_provider_event
#' @export rho_start_response_item
#' @export rho_finish_response_item
NULL

#' Runtime-compiled model catalog
#'
#' The catalog stores model facts as package data. `rho_model_expression()`
#' turns a typed provider profile, protocol, and record into an inspectable R
#' call. `rho_compile_catalog_model()` evaluates that call to produce the S7
#' model value used by provider dispatch. Extensions may add provider profiles,
#' protocols, and expression methods without rewriting the catalog reader.
#'
#' Catalog refresh is an explicit development operation. Package installation
#' and ordinary runtime use never contact a catalog service.
#'
#' @name rho_model_catalog
#' @aliases ModelProtocol OpenAIResponsesProtocol OpenAIChatCompletionsProtocol
#' @aliases AnthropicMessagesProtocol ModelCatalogProvider
#' @aliases OpenAIModelCatalogProvider OpenAICodexModelCatalogProvider
#' @aliases GitHubCopilotModelCatalogProvider AnthropicModelCatalogProvider
#' @aliases ZaiModelCatalogProvider ModelCatalogSource ModelCatalogRecord
#' @aliases ModelCatalog ModelCatalogModelNotFound rho_model_expression
#' @aliases rho_compile_catalog_model rho_default_model_catalog
#' @aliases rho_catalog_models rho_catalog_model rho_catalog_bindings
#' @aliases rho_default_model_bindings
#' @export ModelProtocol
#' @export OpenAIResponsesProtocol
#' @export OpenAIChatCompletionsProtocol
#' @export AnthropicMessagesProtocol
#' @export ModelCatalogProvider
#' @export OpenAIModelCatalogProvider
#' @export OpenAICodexModelCatalogProvider
#' @export GitHubCopilotModelCatalogProvider
#' @export AnthropicModelCatalogProvider
#' @export ZaiModelCatalogProvider
#' @export ModelCatalogSource
#' @export ModelCatalogRecord
#' @export ModelCatalog
#' @export ModelCatalogModelNotFound
#' @export rho_model_expression
#' @export rho_compile_catalog_model
#' @export rho_default_model_catalog
#' @export rho_catalog_models
#' @export rho_catalog_model
#' @export rho_catalog_bindings
#' @export rho_default_model_bindings
NULL

#' Models, providers, and capability operations
#'
#' Shared model facts live in typed capability, limits, and pricing objects.
#' Provider-specific behavior is queried with typed operation values and S7
#' dispatch, avoiding a lowest-common-denominator boolean map.
#'
#' @name rho_ai_providers
#' @aliases Context Model OpenAIResponsesModel OpenAICodexResponsesModel
#' @aliases GitHubCopilotResponsesModel OpenAIChatCompletionsModel
#' @aliases AnthropicMessagesModel ModelCapabilities ModelLimits ModelPricingTier
#' @aliases ModelPricing Provider ProviderCapabilityResolver
#' @aliases ProviderRequestTranslator ProviderInputCompactor ProviderErrorValue
#' @aliases ProviderOperationUnsupported RhoProviderOperation
#' @aliases RhoToolSearchOperation RhoToolReferencesOperation
#' @aliases RhoNativeCompactionOperation RhoCacheRetentionOperation
#' @aliases RhoProviderSupport OpenAIResponsesCompatibility
#' @aliases AnthropicMessagesCompatibility RhoToolPlacement RhoFullToolPlacement
#' @aliases RhoOpenAIToolSearchPlacement RhoAnthropicToolReferencePlacement
#' @aliases FauxProvider OpenAIApi OpenAIApiKeyAuth AnthropicProvider OllamaProvider
#' @aliases rho_context rho_model_capabilities rho_model_limits
#' @aliases rho_model_pricing_tier rho_model_pricing rho_model
#' @aliases rho_thinking_levels rho_supported_thinking_levels
#' @aliases rho_clamp_thinking_level rho_map_thinking_level
#' @aliases rho_model_supports_input rho_model_supports_transport
#' @aliases rho_stream rho_complete rho_provider_error rho_provider_http_error
#' @aliases rho_unsupported_provider_operation rho_provider_support_value
#' @aliases rho_provider_support rho_plan_tools rho_build_provider_request
#' @aliases rho_openai_responses_body
#' @aliases rho_provider_headers
#' @aliases rho_compact_provider_input rho_openai_responses_compatibility
#' @aliases rho_anthropic_messages_compatibility rho_faux_provider
#' @aliases rho_faux_content_events rho_faux_message_events
#' @aliases rho_openai_model rho_openai_provider rho_openai_request
#' @aliases rho_openai_responses_url
#' @aliases rho_anthropic_provider rho_anthropic_messages_request
#' @aliases rho_anthropic_sse_task rho_ollama_provider rho_ollama_chat_request
#' @aliases rho_ollama_chat_task
#' @export Context
#' @export Model
#' @export OpenAIResponsesModel
#' @export OpenAICodexResponsesModel
#' @export GitHubCopilotResponsesModel
#' @export OpenAIChatCompletionsModel
#' @export AnthropicMessagesModel
#' @export ModelCapabilities
#' @export ModelLimits
#' @export ModelPricingTier
#' @export ModelPricing
#' @export Provider
#' @export ProviderCapabilityResolver
#' @export ProviderRequestTranslator
#' @export ProviderInputCompactor
#' @export ProviderErrorValue
#' @export ProviderOperationUnsupported
#' @export RhoProviderOperation
#' @export RhoToolSearchOperation
#' @export RhoToolReferencesOperation
#' @export RhoNativeCompactionOperation
#' @export RhoCacheRetentionOperation
#' @export RhoProviderSupport
#' @export OpenAIResponsesCompatibility
#' @export AnthropicMessagesCompatibility
#' @export RhoToolPlacement
#' @export RhoFullToolPlacement
#' @export RhoOpenAIToolSearchPlacement
#' @export RhoAnthropicToolReferencePlacement
#' @export FauxProvider
#' @export OpenAIApi
#' @export OpenAIApiKeyAuth
#' @export AnthropicProvider
#' @export OllamaProvider
#' @export rho_context
#' @export rho_model_capabilities
#' @export rho_model_limits
#' @export rho_model_pricing_tier
#' @export rho_model_pricing
#' @export rho_model
#' @export rho_thinking_levels
#' @export rho_supported_thinking_levels
#' @export rho_clamp_thinking_level
#' @export rho_map_thinking_level
#' @export rho_model_supports_input
#' @export rho_model_supports_transport
#' @export rho_stream
#' @export rho_complete
#' @export rho_provider_error
#' @export rho_provider_http_error
#' @export rho_unsupported_provider_operation
#' @export rho_provider_support_value
#' @export rho_provider_support
#' @export rho_plan_tools
#' @export rho_build_provider_request
#' @export rho_openai_responses_body
#' @export rho_provider_headers
#' @export rho_compact_provider_input
#' @export rho_openai_responses_compatibility
#' @export rho_anthropic_messages_compatibility
#' @export rho_faux_provider
#' @export rho_faux_content_events
#' @export rho_faux_message_events
#' @export rho_openai_model
#' @export rho_openai_provider
#' @export rho_openai_request
#' @export rho_openai_responses_url
#' @export rho_anthropic_provider
#' @export rho_anthropic_messages_request
#' @export rho_anthropic_sse_task
#' @export rho_ollama_provider
#' @export rho_ollama_chat_request
#' @export rho_ollama_chat_task
#' @importFrom rho.http RhoHttpError RhoHttpStatusError RhoHttpTransportError
#' @importFrom rho.http RhoSseEvent
NULL

#' Explicit credentials, login effects, and provider catalog state
#'
#' Credentials are owned by a `CredentialStore`; login interaction is owned by
#' a `LoginIO`. Reads, refreshes, writes, prompts, and notifications are explicit
#' async operations. `RhoModels` owns provider selection and serialized refresh
#' gates instead of relying on process-global auth state.
#'
#' @name rho_ai_auth
#' @aliases CredentialStore OAuthAuth LoginIO RhoCredential RhoApiKeyCredential
#' @aliases RhoOAuthCredential RhoModelAuth RhoAuthResolution RhoApiKeyAuth
#' @aliases RhoOAuthAuth RhoFunctionOAuthAuth RhoProviderAuth RhoCredentialGate
#' @aliases RhoMemoryCredentialStore RhoAuthPrompt RhoTextAuthPrompt
#' @aliases RhoSecretAuthPrompt RhoManualCodeAuthPrompt RhoSelectAuthPrompt
#' @aliases RhoAuthEvent RhoAuthUrlEvent RhoDeviceCodeEvent RhoAuthProgressEvent
#' @aliases RhoFunctionLoginIO RhoProvider RhoModels AuthErrorValue
#' @aliases rho_api_key_credential rho_model_auth rho_api_key_auth rho_oauth_auth
#' @aliases rho_provider_auth rho_credential_gate rho_memory_credential_store
#' @aliases rho_login_io rho_provider rho_models rho_models_provider
#' @aliases rho_login_provider rho_resolve_model_auth rho_credential_read
#' @aliases rho_credential_modify rho_credential_delete rho_auth_login
#' @aliases rho_auth_refresh rho_auth_to_request rho_auth_prompt rho_auth_notify
#' @aliases rho_auth_error OpenAICodexApi OpenAICodexOAuthAuth
#' @aliases rho_openai_codex_auth rho_openai_codex_credential
#' @aliases rho_load_openai_codex_credential rho_openai_codex_provider
#' @aliases rho_openai_codex_model rho_openai_codex_request
#' @aliases GitHubCopilotClientIdentity GitHubCopilotEndpoints
#' @aliases GitHubCopilotDeviceAuthorization
#' @aliases GitHubCopilotCredential GitHubCopilotModelAuth
#' @aliases GitHubCopilotOAuthAuth GitHubCopilotApi
#' @aliases rho_github_copilot_client_identity rho_github_copilot_auth
#' @aliases rho_github_copilot_credential rho_github_copilot_credential_from_github_token
#' @aliases rho_load_github_copilot_credential rho_github_copilot_provider
#' @aliases rho_github_copilot_model rho_github_copilot_request
#' @aliases rho_message_initiator rho_has_image_input
#' @export CredentialStore
#' @export OAuthAuth
#' @export LoginIO
#' @export RhoCredential
#' @export RhoApiKeyCredential
#' @export RhoOAuthCredential
#' @export RhoModelAuth
#' @export RhoAuthResolution
#' @export RhoApiKeyAuth
#' @export RhoOAuthAuth
#' @export RhoFunctionOAuthAuth
#' @export RhoProviderAuth
#' @export RhoCredentialGate
#' @export RhoMemoryCredentialStore
#' @export RhoAuthPrompt
#' @export RhoTextAuthPrompt
#' @export RhoSecretAuthPrompt
#' @export RhoManualCodeAuthPrompt
#' @export RhoSelectAuthPrompt
#' @export RhoAuthEvent
#' @export RhoAuthUrlEvent
#' @export RhoDeviceCodeEvent
#' @export RhoAuthProgressEvent
#' @export RhoFunctionLoginIO
#' @export RhoProvider
#' @export RhoModels
#' @export AuthErrorValue
#' @export rho_api_key_credential
#' @export rho_model_auth
#' @export rho_api_key_auth
#' @export rho_oauth_auth
#' @export rho_provider_auth
#' @export rho_credential_gate
#' @export rho_memory_credential_store
#' @export rho_login_io
#' @export rho_provider
#' @export rho_models
#' @export rho_models_provider
#' @export rho_login_provider
#' @export rho_resolve_model_auth
#' @export rho_credential_read
#' @export rho_credential_modify
#' @export rho_credential_delete
#' @export rho_auth_login
#' @export rho_auth_refresh
#' @export rho_auth_to_request
#' @export rho_auth_prompt
#' @export rho_auth_notify
#' @export rho_auth_error
#' @export OpenAICodexApi
#' @export OpenAICodexOAuthAuth
#' @export rho_openai_codex_auth
#' @export rho_openai_codex_credential
#' @export rho_load_openai_codex_credential
#' @export rho_openai_codex_provider
#' @export rho_openai_codex_model
#' @export rho_openai_codex_request
#' @export GitHubCopilotClientIdentity
#' @export GitHubCopilotEndpoints
#' @export GitHubCopilotDeviceAuthorization
#' @export GitHubCopilotCredential
#' @export GitHubCopilotModelAuth
#' @export GitHubCopilotOAuthAuth
#' @export GitHubCopilotApi
#' @export rho_github_copilot_client_identity
#' @export rho_github_copilot_auth
#' @export rho_github_copilot_credential
#' @export rho_github_copilot_credential_from_github_token
#' @export rho_load_github_copilot_credential
#' @export rho_github_copilot_provider
#' @export rho_github_copilot_model
#' @export rho_github_copilot_request
#' @export rho_message_initiator
#' @export rho_has_image_input
NULL

#' Typed OpenAI Responses wire protocol
#'
#' The OpenAI Responses decoder maps JSON/SSE payloads to typed wire event and
#' output-item classes before reducing them to normalized assistant events.
#' Provider extensions may add narrower S7 methods for new item or event types.
#'
#' @name rho_openai_responses_wire
#' @aliases OpenAIResponseDecoder OpenAIResponseSlot OpenAIResponseItem
#' @aliases OpenAIReasoningItem OpenAIMessageItem OpenAIFunctionCallItem
#' @aliases OpenAIUnsupportedItem OpenAIResponseWireEvent OpenAIResponseIgnored
#' @aliases OpenAIResponseCreated OpenAIResponseOutputItemAdded
#' @aliases OpenAIResponseThinkingDelta OpenAIResponseThinkingBreak
#' @aliases OpenAIResponseTextDelta OpenAIResponseToolArgumentsDelta
#' @aliases OpenAIResponseToolArgumentsDone OpenAIResponseOutputItemDone
#' @aliases OpenAIResponseCompleted OpenAIResponseIncomplete OpenAIResponseError
#' @aliases rho_openai_responses_decoder
#' @export OpenAIResponseDecoder
#' @export OpenAIResponseSlot
#' @export OpenAIResponseItem
#' @export OpenAIReasoningItem
#' @export OpenAIMessageItem
#' @export OpenAIFunctionCallItem
#' @export OpenAIUnsupportedItem
#' @export OpenAIResponseWireEvent
#' @export OpenAIResponseIgnored
#' @export OpenAIResponseCreated
#' @export OpenAIResponseOutputItemAdded
#' @export OpenAIResponseThinkingDelta
#' @export OpenAIResponseThinkingBreak
#' @export OpenAIResponseTextDelta
#' @export OpenAIResponseToolArgumentsDelta
#' @export OpenAIResponseToolArgumentsDone
#' @export OpenAIResponseOutputItemDone
#' @export OpenAIResponseCompleted
#' @export OpenAIResponseIncomplete
#' @export OpenAIResponseError
#' @export rho_openai_responses_decoder
NULL
