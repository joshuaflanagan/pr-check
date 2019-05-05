require "pull_request_identifier"

RSpec.describe "PullRequestIdentifier" do
  context "when the URL refers to a pull request" do
    let(:url){
      "https://github.com/ExampleOrg/example-Repo/pull/42"
    }

    it "returns a lower-cased portion of the URL without the scheme" do
      pr_id = PullRequestIdentifier.(url)

      expect(pr_id).to eq("github.com/exampleorg/example-repo/pull/42")
    end

  end

  context "when the URL does not refer to a pull request" do
    let(:url){
      "https://github.com/ExampleOrg/example-Repo/blob/ac69b4dc74fdf94ce4f3d8ae113f7f3c2d6eec25/fruits.txt"
    }

    it "returns nil" do
      pr_id = PullRequestIdentifier.(url)

      expect(pr_id).to be_nil
    end
  end
end
