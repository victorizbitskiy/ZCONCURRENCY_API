*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
*----------------------------------------------------------------------*
*       CLASS lcl_context DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_context DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES: if_serializable_object.

    TYPES: BEGIN OF ty_params,
             param TYPE i,
           END OF ty_params.

    METHODS: constructor IMPORTING is_params TYPE ty_params,
      get RETURNING VALUE(rs_params) TYPE ty_params.

  PRIVATE SECTION.
    DATA: ms_params TYPE ty_params.

ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS lcl_task DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_task DEFINITION INHERITING FROM zcl_capi_abstract_task FINAL.
  PUBLIC SECTION.

    METHODS: constructor IMPORTING io_context TYPE REF TO lcl_context,
      zif_capi_callable~call REDEFINITION.

  PRIVATE SECTION.
    DATA: mo_context TYPE REF TO lcl_context.
    DATA: mv_res TYPE i.

ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS lcl_result DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_result DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES: if_serializable_object.

    METHODS: constructor IMPORTING iv_result TYPE i,
      get RETURNING VALUE(rv_result) TYPE string.

  PRIVATE SECTION.
    DATA: mv_result TYPE i.

ENDCLASS.

CLASS lcl_context IMPLEMENTATION.
  METHOD constructor.
    ms_params = is_params.
  ENDMETHOD.

  METHOD get.
    rs_params = ms_params.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
*       CLASS lcl_task DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_task IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mo_context = io_context.
  ENDMETHOD.

  METHOD zif_capi_callable~call.
    DATA: ls_params TYPE lcl_context=>ty_params.

    ls_params = mo_context->get( ).
    mv_res = ls_params-param ** 2.

    CREATE OBJECT ro_result
      TYPE
      lcl_result
      EXPORTING
        iv_result = mv_res.

  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
*       CLASS lcl_result IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_result IMPLEMENTATION.
  METHOD constructor.
    mv_result = iv_result.
  ENDMETHOD.

  METHOD get.
    rv_result = mv_result.
  ENDMETHOD.
ENDCLASS.

CLASS ltc_capi_executor_service DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: mo_cut   TYPE REF TO zif_capi_executor_service,
          mo_tasks TYPE REF TO zcl_capi_collection.

    METHODS:
      setup,
      teardown,
      _invoke_all FOR TESTING.

ENDCLASS.       "ltcl_Commonregex

CLASS ltc_capi_executor_service IMPLEMENTATION.
  METHOD setup.
    DATA: lo_task            TYPE REF TO lcl_task,
          lo_context         TYPE REF TO lcl_context,
          ls_params          TYPE lcl_context=>ty_params,
          lo_message_handler TYPE REF TO zcl_capi_message_handler,
          lo_results         TYPE REF TO zif_capi_collection,
          lv_result          TYPE string.

    CREATE OBJECT mo_tasks.

    DO 5 TIMES.
      ls_params-param = sy-index.

      CREATE OBJECT lo_context
        EXPORTING
          is_params = ls_params.

      CREATE OBJECT lo_task
        EXPORTING
          io_context = lo_context.

      mo_tasks->zif_capi_collection~add( lo_task ).
    ENDDO.

    CREATE OBJECT lo_message_handler.

    mo_cut = zcl_capi_executors=>new_fixed_thread_pool( iv_server_group             = 'parallel_generators'
                                                        iv_n_threads                = 4
                                                        iv_no_resubmission_on_error = abap_false
                                                        io_capi_message_handler     = lo_message_handler ).


  ENDMETHOD.

  METHOD teardown.

  ENDMETHOD.

  METHOD _invoke_all.
    DATA: lo_result           TYPE REF TO lcl_result,
          lo_results          TYPE REF TO zif_capi_collection,
          lo_results_iterator TYPE REF TO zif_capi_iterator,
          lv_result_exp       TYPE i,
          lv_result_act       TYPE i.

    lo_results = mo_cut->invoke_all( mo_tasks ).
    lo_results_iterator = lo_results->get_iterator( ).

    WHILE lo_results_iterator->has_next( ).

      lv_result_exp = sy-index ** 2.

      lo_result ?= lo_results_iterator->next( ).
      lv_result_act = lo_result->get( ).

      cl_aunit_assert=>assert_equals( exp = lv_result_exp
                                      act = lv_result_act
                                      msg = 'Testing invoke_all( )' ).
    ENDWHILE.

  ENDMETHOD.
ENDCLASS.
