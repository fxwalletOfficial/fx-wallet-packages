import ISolanaProvider from '../types/SolanaProvider';
import { registerWallet } from './register';

function initialize(fx: ISolanaProvider): void {
  registerWallet(fx.getInstanceWithAdapter());
}

export default initialize;
