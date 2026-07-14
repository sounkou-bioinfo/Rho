#' Message content and tool contracts
#'
#' Messages contain typed content objects rather than discriminator strings.
#' Tool execution is asynchronous, and overlap is represented by an S7 value
#' that the agent can dispatch on.
#'
#' @name rho_ai_messages
#' @aliases TextContent ThinkingContent ImageContent ArtifactRefContent ToolCall
#' @aliases Usage UserMessage AssistantMessage ToolResultMessage ToolOverlap
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
#' @export Usage
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

#' Models, providers, and capability operations
#'
#' Shared model facts live in typed capability, limits, and pricing objects.
#' Provider-specific behavior is queried with typed operation values and S7
#' dispatch, avoiding a lowest-common-denominator boolean map.
#'
#' @name rho_ai_providers
#' @aliases Context Model ModelCapabilities ModelLimits ModelPricingTier
#' @aliases ModelPricing Provider ProviderCapabilityResolver
#' @aliases ProviderRequestTranslator ProviderInputCompactor ProviderErrorValue
#' @aliases ProviderOperationUnsupported RhoProviderOperation
#' @aliases RhoToolSearchOperation RhoToolReferencesOperation
#' @aliases RhoNativeCompactionOperation RhoCacheRetentionOperation
#' @aliases RhoProviderSupport OpenAIResponsesCompatibility
#' @aliases AnthropicMessagesCompatibility RhoToolPlacement RhoFullToolPlacement
#' @aliases RhoOpenAIToolSearchPlacement RhoAnthropicToolReferencePlacement
#' @aliases FauxProvider OpenAIProvider AnthropicProvider OllamaProvider
#' @aliases rho_context rho_model_capabilities rho_model_limits
#' @aliases rho_model_pricing_tier rho_model_pricing rho_model
#' @aliases rho_thinking_levels rho_supported_thinking_levels
#' @aliases rho_clamp_thinking_level rho_map_thinking_level
#' @aliases rho_model_supports_input rho_model_supports_transport
#' @aliases rho_stream rho_complete rho_provider_error
#' @aliases rho_unsupported_provider_operation rho_provider_support_value
#' @aliases rho_provider_support rho_plan_tools rho_build_provider_request
#' @aliases rho_compact_provider_input rho_openai_responses_compatibility
#' @aliases rho_anthropic_messages_compatibility rho_faux_provider
#' @aliases rho_faux_content_events rho_faux_message_events
#' @aliases rho_openai_provider rho_openai_chat_request rho_openai_sse_task
#' @aliases rho_anthropic_provider rho_anthropic_messages_request
#' @aliases rho_anthropic_sse_task rho_ollama_provider rho_ollama_chat_request
#' @aliases rho_ollama_chat_task
#' @export Context
#' @export Model
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
#' @export OpenAIProvider
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
#' @export rho_unsupported_provider_operation
#' @export rho_provider_support_value
#' @export rho_provider_support
#' @export rho_plan_tools
#' @export rho_build_provider_request
#' @export rho_compact_provider_input
#' @export rho_openai_responses_compatibility
#' @export rho_anthropic_messages_compatibility
#' @export rho_faux_provider
#' @export rho_faux_content_events
#' @export rho_faux_message_events
#' @export rho_openai_provider
#' @export rho_openai_chat_request
#' @export rho_openai_sse_task
#' @export rho_anthropic_provider
#' @export rho_anthropic_messages_request
#' @export rho_anthropic_sse_task
#' @export rho_ollama_provider
#' @export rho_ollama_chat_request
#' @export rho_ollama_chat_task
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
#' @aliases rho_openai_codex_spark rho_openai_codex_request
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
#' @export rho_openai_codex_spark
#' @export rho_openai_codex_request
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
#' @aliases rho_openai_codex_decoder
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
#' @export rho_openai_codex_decoder
NULL
