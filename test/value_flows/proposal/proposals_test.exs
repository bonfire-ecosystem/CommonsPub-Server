# SPDX-License-Identifier: AGPL-3.0-only#
defmodule ValueFlows.Proposal.ProposalsTest do
  use MoodleNetWeb.ConnCase, async: true

  import CommonsPub.Utils.Trendy, only: [some: 2]
  import MoodleNet.Test.Faking

  import Measurement.Simulate
  import Measurement.Test.Faking

  import ValueFlows.Simulate
  import ValueFlows.Test.Faking

  alias ValueFlows.Proposals

  describe "one" do
    test "fetches an existing proposal by ID" do
      user = fake_user!()
      proposal = fake_proposal!(user)

      assert {:ok, fetched} = Proposals.one(id: proposal.id)
      assert_proposal(proposal, fetched)
      assert {:ok, fetched} = Proposals.one(user: user)
      assert_proposal(proposal, fetched)
      # TODO
      # assert {:ok, fetched} = Intents.one(context: comm)
    end
  end

  describe "create" do
    test "can create a proposal" do
      user = fake_user!()

      assert {:ok, proposal} = Proposals.create(user, proposal())
      assert_proposal(proposal)
    end
  end

  describe "one_proposed_intent" do
    test "fetches an existing proposed intent" do
      user = fake_user!()
      proposal = fake_proposal!(user)
      intent = fake_intent!(user)

      proposed_intent = fake_proposed_intent!(proposal, intent)
      assert {:ok, fetched} = Proposals.one_proposed_intent(id: proposed_intent.id)
      assert_proposed_intent(fetched)
      assert fetched.id == proposed_intent.id

      assert {:ok, fetched} = Proposals.one_proposed_intent(publishes_id: intent.id)
      assert fetched.publishes_id == intent.id

      assert {:ok, fetched} = Proposals.one_proposed_intent(published_in_id: proposal.id)
      assert fetched.published_in_id == proposal.id
    end

    test "default filter ignores removed items" do
      user = fake_user!()
      proposed_intent = fake_proposed_intent!(
        fake_proposal!(user),
        fake_intent!(user)
      )

      assert {:ok, proposed_intent} =
        Proposals.delete_proposed_intent(proposed_intent)

      assert {:error, %MoodleNet.Common.NotFoundError{}} =
        Proposals.one_proposed_intent([:default, id: proposed_intent.id])
    end
  end

  describe "many_proposed_intent" do
    test "returns a list of items matching criteria" do
      user = fake_user!()
      proposal = fake_proposal!(user)
      intent = fake_intent!(user)
      proposed_intents = some(5, fn ->
        fake_proposed_intent!(proposal, intent)
      end)

      assert {:ok, fetched} = Proposals.many_proposed_intents()
      assert Enum.count(fetched) == 5
      assert {:ok, fetched} = Proposals.many_proposed_intents(
        id: hd(proposed_intents).id
      )
      assert Enum.count(fetched) == 1
    end
  end

  describe "propose_intent" do
    test "creates a new proposed intent" do
      user = fake_user!()
      intent = fake_intent!(user)
      proposal = fake_proposal!(user)

      assert {:ok, proposed_intent} =
        Proposals.propose_intent(proposal, intent, proposed_intent())
      assert_proposed_intent(proposed_intent)
    end
  end

  describe "delete_proposed_intent" do
    test "deletes an existing proposed intent" do
      user = fake_user!()
      intent = fake_intent!(user)
      proposal = fake_proposal!(user)
      proposed_intent = fake_proposed_intent!(proposal, intent)
      assert {:ok, proposed_intent} = Proposals.delete_proposed_intent(proposed_intent)
      assert proposed_intent.deleted_at
    end
  end
end