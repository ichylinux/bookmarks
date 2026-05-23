@facebook
Feature: Facebook OAuth Button

  Scenario: Facebookボタンがサインインページとサインアップページに表示される
    Given サインインページを開く
    Then Facebookサインインボタンが表示される
    When サインアップページを開く
    Then Facebookサインインボタンが表示される
