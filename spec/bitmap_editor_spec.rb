require 'bitmap_editor'

RSpec.describe BitmapEditor, "#run" do
  TEST_FILE_PATH = "examples/test_file.txt"

  before(:each) do
    @editor = BitmapEditor.new
  end

  after(:each) do
    File.delete(TEST_FILE_PATH) if File.exists?(TEST_FILE_PATH)
  end

  context "without argument" do
    it "raises a StandardError" do
      expect { @editor.run }.to raise_error(StandardError)
    end
  end

  context "with non existing file file" do
    it "raises a StandardError" do
      expect { @editor.run('examples/not_existing_file.txt') }.to raise_error(StandardError)
    end
  end

  context "with valid file" do
    it "returns correct output" do
      File.open(TEST_FILE_PATH, "a") { |f|
        f.write("I 5 6\nL 1 3 A\nV 2 3 6 W\nH 3 5 2 Z\nS")
      }
      expected = "OOOOO\nOOZZZ\nAWOOO\nOWOOO\nOWOOO\nOWOOO"
      expect(@editor.run(TEST_FILE_PATH)).to eq(expected)
    end

    it "returns correct output for `I` cmd" do
      File.open(TEST_FILE_PATH, "a") { |f|
        f.write("I 4 4\nS")
      }
      expected = "OOOO\nOOOO\nOOOO\nOOOO"
      expect(@editor.run(TEST_FILE_PATH)).to eq(expected)
    end

    it "returns correct output for `L` cmd" do
      File.open(TEST_FILE_PATH, "a") { |f|
        f.write("I 4 4\nL 1 1 A\nS")
      }
      expected = "AOOO\nOOOO\nOOOO\nOOOO"
      expect(@editor.run(TEST_FILE_PATH)).to eq(expected)
    end

    it "returns correct output for `V` cmd" do
      File.open(TEST_FILE_PATH, "a") { |f|
        f.write("I 4 4\nV 3 3 4 W\nS")
      }
      expected = "OOOO\nOOOO\nOOWO\nOOWO"
      expect(@editor.run(TEST_FILE_PATH)).to eq(expected)
    end

    it "returns correct output for `H` cmd" do
      File.open(TEST_FILE_PATH, "a") { |f|
        f.write("I 4 4\nH 3 3 4 W\nS")
      }
      expected = "OOOO\nOOOO\nOOOO\nOOWO"
      expect(@editor.run(TEST_FILE_PATH)).to eq(expected)
    end

    it "returns correct output for `C` cmd" do
      File.open(TEST_FILE_PATH, "a") { |f|
        f.write("I 4 4\nL 1 1 A\nC\nS")
      }
      expected = "OOOO\nOOOO\nOOOO\nOOOO"
      expect(@editor.run(TEST_FILE_PATH)).to eq(expected)
    end

    it "returns output on first `S` command and stops" do
      File.open(TEST_FILE_PATH, "a") { |f|
        f.write("I 5 6\nL 1 3 A\nV 2 3 6 W\nH 3 5 2 Z\nS\nC\nS")
      }
      expected = "OOOOO\nOOZZZ\nAWOOO\nOWOOO\nOWOOO\nOWOOO"
      expect(@editor.run(TEST_FILE_PATH)).to eq(expected)
    end
  end

  context "with invalid commands" do
    context "InvalidCommandError" do
      it "raises when command doesn't exist" do
        File.open(TEST_FILE_PATH, "a") { |f|
          f.write("M")
        }
        expect { @editor.run(TEST_FILE_PATH) }.to raise_error(InvalidCommandError)
      end

      it "raises when there's an empty line" do
        File.open(TEST_FILE_PATH, "a") { |f|
          f.write("\nI 5")
        }
        expect { @editor.run(TEST_FILE_PATH) }.to raise_error(InvalidCommandError)
      end
    end

    context "InvalidArgumentError" do
      it "raises when any argument is missing" do
        File.open(TEST_FILE_PATH, "a") { |f|
          f.write("I 5")
        }
        expect { @editor.run(TEST_FILE_PATH) }.to raise_error(InvalidArgumentError)
      end

      it "raises when wrong argument pattern in line" do
        File.open(TEST_FILE_PATH, "a") { |f|
          f.write("I 5 6 7")
        }
        expect { @editor.run(TEST_FILE_PATH) }.to raise_error(InvalidArgumentError)
      end

      it "raises when wrong integer argument" do
        File.open(TEST_FILE_PATH, "a") { |f|
          f.write("I 0 6")
        }
        expect { @editor.run(TEST_FILE_PATH) }.to raise_error(InvalidArgumentError)
      end
    end

    context "MatrixNotPresentError" do
      it "raises when no matrix present when running draw cmd" do
        File.open(TEST_FILE_PATH, "a") { |f|
          f.write("C")
        }
        expect { @editor.run(TEST_FILE_PATH) }.to raise_error(MatrixNotPresentError)
      end
    end

    context "MatrixNoDupError" do
      it "raises when tries to build multiple matrices" do
        File.open(TEST_FILE_PATH, "a") { |f|
          f.write("I 5 6\nI 4 5")
        }
        expect { @editor.run(TEST_FILE_PATH) }.to raise_error(MatrixNoDupError)
      end
    end
  end
end
